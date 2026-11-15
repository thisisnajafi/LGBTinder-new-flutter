import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/payments/data/services/plan_limits_service.dart';
import '../../../routes/app_router.dart';
import '../../../shared/utils/plan_guard.dart';
import '../../../shared/services/agora_service.dart';
import '../../../shared/services/incoming_call_handler.dart';
import '../data/models/active_call_session.dart';
import '../data/models/call.dart';
import '../data/models/incoming_call_data.dart';
import '../data/services/call_kit_service.dart';
import '../pages/outgoing_call_page.dart';
import '../presentation/widgets/call_permission_sheet.dart';

/// GoRouter location for the callee joining an already-accepted call.
String activeCallLocation({
  required int callId,
  required int recipientId,
  required String recipientName,
  String? recipientAvatarUrl,
  required OutgoingCallType type,
}) {
  return Uri(
    path: AppRoutes.outgoingCall,
    queryParameters: {
      'callId': callId.toString(),
      'recipientId': recipientId.toString(),
      'recipientName': recipientName,
      if (recipientAvatarUrl != null && recipientAvatarUrl.isNotEmpty)
        'avatarUrl': recipientAvatarUrl,
      'type': type == OutgoingCallType.video ? 'video' : 'voice',
      'callee': '1',
    },
  ).toString();
}

/// Location from a restored / accepted incoming payload.
String activeCallLocationFromIncoming(IncomingCallData data) {
  return activeCallLocation(
    callId: int.tryParse(data.callId) ?? 0,
    recipientId: data.callerId,
    recipientName: data.callerName,
    recipientAvatarUrl: data.callerAvatar,
    type: data.isVideo ? OutgoingCallType.video : OutgoingCallType.voice,
  );
}

/// Opens the per-person call history page (not chat).
void openPeerCallHistory({
  required BuildContext context,
  required int userId,
  required String name,
  String? avatarUrl,
}) {
  context.push(
    Uri(
      path: AppRoutes.peerCallHistory,
      queryParameters: {
        'userId': userId.toString(),
        'userName': name,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      },
    ).toString(),
  );
}
/// Opens the calling page immediately. The page shows Connecting… and starts
/// (or rejoins) the call so status messages never land on chat.
Future<void> startOutgoingCall({
  required BuildContext context,
  required WidgetRef ref,
  required int recipientId,
  required String recipientName,
  String? recipientAvatarUrl,
  required OutgoingCallType type,
}) async {
  if (!context.mounted) return;
  final guard = PlanGuard(ref.read(planLimitsServiceProvider));
  final access = type == OutgoingCallType.video
      ? await guard.canMakeVideoCall()
      : await guard.canMakeVoiceCall();
  if (!context.mounted) return;
  if (!access.isAllowed) {
    _openCallUpgrade(
      context,
      video: type == OutgoingCallType.video,
      message: access.errorMessage,
    );
    return;
  }
  final allowed = await ensureCallMediaPermissions(
    context,
    video: type == OutgoingCallType.video,
  );
  if (!allowed || !context.mounted) return;
  context.push(
    Uri(
      path: AppRoutes.outgoingCall,
      queryParameters: {
        'callId': '0',
        'recipientId': recipientId.toString(),
        'recipientName': recipientName,
        if (recipientAvatarUrl != null && recipientAvatarUrl.isNotEmpty)
          'avatarUrl': recipientAvatarUrl,
        'type': type == OutgoingCallType.video ? 'video' : 'voice',
        'initiate': '1',
      },
    ).toString(),
  );
}

void _openCallUpgrade(
  BuildContext context, {
  required bool video,
  String? message,
}) {
  context.push(
    Uri(
      path: AppRoutes.featureLocked,
      queryParameters: {
        'title': video ? 'Video calls' : 'Voice calls',
        'desc': message ??
            (video
                ? 'Video calls require Golden. Upgrade to connect face-to-face.'
                : 'Voice calls require Premium. Upgrade to talk live.'),
        'minTier': video ? 'golden' : 'silder',
      },
    ).toString(),
  );
}

/// Opens the upgrade screen for a server call-tier rejection, then leaves
/// the call route when one is already showing.
void openCallTierUpgrade(
  BuildContext context, {
  required String errorCode,
  String? message,
}) {
  if (!context.mounted) return;
  final router = GoRouter.of(context);
  final video = errorCode == 'VIDEO_CALL_REQUIRES_GOLDEN';
  final onCall = GoRouterState.of(context).uri.path == AppRoutes.outgoingCall;
  if (onCall) {
    leaveCallRoute(context);
  }
  router.push(
    Uri(
      path: AppRoutes.featureLocked,
      queryParameters: {
        'title': video ? 'Video calls' : 'Voice calls',
        'desc': message ??
            (video
                ? 'Video calls require Golden. Upgrade to connect face-to-face.'
                : 'Voice calls require Premium. Upgrade to talk live.'),
        'minTier': video ? 'golden' : 'silder',
      },
    ).toString(),
  );
}

/// True when [path] is a full-screen call UI (incoming or in-call).
bool isCallUiPath(String path) =>
    path == AppRoutes.incomingCall || path == AppRoutes.outgoingCall;

/// Leaves every stacked call route (incoming + in-call) after hang-up.
///
/// A bare single [pop] leaves a duplicate incoming page (null state = black
/// empty scaffold). Keep popping while the top route is call UI, then fall
/// back to [fallback] when the stack is empty / stuck on Splash.
///
/// Prefer the top [RouteMatch] location over [uri.path]: after imperative
/// pushes go_router can report the parent URI while call pages are still on
/// the stack (the black-screen race on hang-up).
void leaveCallRoutes(
  GoRouter router, {
  String? callId,
  String fallback = AppRoutes.home,
}) {
  if (callId != null && callId.isNotEmpty) {
    unawaited(CallKitService.instance.endCall(callId));
    IncomingCallHandler.clearPendingCallData();
  }

  const maxPops = 10;
  for (var i = 0; i < maxPops; i++) {
    final path = _topStackPath(router);
    if (!isCallUiPath(path)) return;

    if (_callStackHasDeadSplash(router) || !router.canPop()) {
      router.go(fallback);
      return;
    }
    router.pop();
  }

  if (isCallUiPath(_topStackPath(router))) {
    router.go(fallback);
  }
}

/// Leaves the call screen safely after hangup / reject / failure.
///
/// Cold-start Accept can stack the call on Splash. A bare [pop] then reveals a
/// dead Splash (`_redirected` already true) and the UI never recovers. Prefer
/// popping all call routes when a real parent exists; otherwise (or if Splash
/// is underneath) [go] home.
///
/// Prefer [router] when the triggering widget may already be disposed.
void leaveCallRoute(
  BuildContext? context, {
  String? callId,
  GoRouter? router,
  String fallback = AppRoutes.home,
}) {
  final goRouter = router ??
      (context != null && context.mounted ? GoRouter.of(context) : null);
  if (goRouter == null) {
    if (callId != null && callId.isNotEmpty) {
      unawaited(CallKitService.instance.endCall(callId));
      IncomingCallHandler.clearPendingCallData();
    }
    return;
  }
  leaveCallRoutes(goRouter, callId: callId, fallback: fallback);
}

String _currentPath(GoRouter router) {
  try {
    return router.routerDelegate.currentConfiguration.uri.path;
  } catch (_) {
    return '';
  }
}

/// Top-most matched location (imperative push stack aware).
String _topStackPath(GoRouter router) {
  try {
    final matches = router.routerDelegate.currentConfiguration.matches;
    for (var i = matches.length - 1; i >= 0; i--) {
      final loc = matches[i].matchedLocation;
      if (loc.isNotEmpty) return loc;
    }
  } catch (_) {}
  return _currentPath(router);
}

/// Whether the navigator stack already contains a call screen.
bool stackContainsCallUi(GoRouter router) {
  try {
    final matches = router.routerDelegate.currentConfiguration.matches;
    for (final match in matches) {
      if (isCallUiPath(match.matchedLocation)) return true;
    }
  } catch (_) {}
  return isCallUiPath(_currentPath(router));
}

/// Opens the in-call page, replacing a top incoming route when present.
void openActiveCallReplacingIncoming(
  GoRouter router,
  IncomingCallData data,
) {
  final loc = activeCallLocationFromIncoming(data);
  final path = _topStackPath(router);
  if (path == AppRoutes.incomingCall) {
    unawaited(router.pushReplacement(loc));
    return;
  }
  router.push(loc);
}

/// Re-opens the live call screen without joining Agora again.
///
/// Looks at the whole stack, not `currentConfiguration.uri`: the call page is
/// pushed imperatively, so the URI still reports the page underneath and a
/// second in-call page (second Agora join) would be stacked on top.
void restoreActiveCallRoute(GoRouter router, ActiveCallSession session) {
  if (isActiveCallRouteOnStack(router, session.callId.toString())) {
    return;
  }
  router.push(session.routeLocation);
}

/// Top-most matched location, aware of imperatively pushed routes.
String topCallStackPath(GoRouter router) => _topStackPath(router);

/// True when an in-call page for [callId] is already on the navigator stack.
bool isActiveCallRouteOnStack(GoRouter router, String callId) {
  if (callId.isEmpty) return false;
  try {
    final config = router.routerDelegate.currentConfiguration;
    for (final match in config.matches) {
      if (match.matchedLocation != AppRoutes.outgoingCall) continue;
      final uri = match is ImperativeRouteMatch ? match.matches.uri : config.uri;
      if (uri.queryParameters['callId'] == callId) return true;
    }
  } catch (_) {}
  return false;
}

/// Removes a full-screen incoming page that no longer has a call to show
/// (declined, caller cancelled, ring timeout, permission denied).
///
/// Only pops while the *top* route is `/call/incoming`, so it can never pop
/// the page underneath or a live in-call page. Returns true when it left.
bool leaveIncomingCallRoute(
  GoRouter router, {
  String fallback = AppRoutes.home,
}) {
  var left = false;
  const maxPops = 4;
  for (var i = 0; i < maxPops; i++) {
    if (_topStackPath(router) != AppRoutes.incomingCall) return left;
    if (_callStackHasDeadSplash(router) || !router.canPop()) {
      router.go(fallback);
      return true;
    }
    router.pop();
    left = true;
  }
  if (_topStackPath(router) == AppRoutes.incomingCall) {
    router.go(fallback);
    return true;
  }
  return left;
}

bool _stackContainsSplash(GoRouter router) {
  try {
    final matches = router.routerDelegate.currentConfiguration.matches;
    for (final match in matches) {
      final loc = match.matchedLocation;
      // Splash route is `/`. Only treat an exact splash page under a call
      // route as dead — do not confuse other paths that happen to be `/`.
      if (loc == AppRoutes.splash) {
        return true;
      }
    }
    return router.routerDelegate.currentConfiguration.uri.path ==
        AppRoutes.splash;
  } catch (_) {
    return false;
  }
}

/// Splash under a call route is unrecoverable after cold-start Accept.
bool _callStackHasDeadSplash(GoRouter router) {
  if (!_stackContainsSplash(router)) return false;
  return stackContainsCallUi(router);
}

/// Seats Home under the active call using a captured [GoRouter] (safe after Splash unmounts).
Future<void> openActiveCallOverHome(
  GoRouter router,
  IncomingCallData data,
) async {
  final callLoc = activeCallLocationFromIncoming(data);
  router.go(AppRoutes.home);
  await Future<void>.delayed(Duration.zero);
  await WidgetsBinding.instance.endOfFrame;
  router.push(callLoc);
  IncomingCallHandler.clearPendingCallData();
  unawaited(CallKitService.instance.endCall(data.callId));
}

/// Opens [OutgoingCallPage] for callee after accepting (call already active).
void openActiveCallPage({
  required BuildContext context,
  required int callId,
  required int recipientId,
  required String recipientName,
  String? recipientAvatarUrl,
  required OutgoingCallType type,
}) {
  final router = GoRouter.of(context);
  final loc = activeCallLocation(
    callId: callId,
    recipientId: recipientId,
    recipientName: recipientName,
    recipientAvatarUrl: recipientAvatarUrl,
    type: type,
  );
  final path = _topStackPath(router);
  if (path == AppRoutes.incomingCall) {
    unawaited(router.pushReplacement(loc));
    return;
  }
  router.push(loc);
}

/// Rejoins a ringing or active call from the messenger Calls list.
Future<void> openExistingCallPage({
  required BuildContext context,
  required Call call,
  required int currentUserId,
}) async {
  if (!context.mounted) return;
  final alreadyLive = AgoraService().isInCall;
  if (!alreadyLive) {
    final allowed = await ensureCallMediaPermissions(
      context,
      video: call.isVideoCall,
    );
    if (!allowed || !context.mounted) return;
  }

  final peerId = call.getOtherParticipantId(currentUserId);
  final peer = call.callerId == currentUserId ? call.receiver : call.caller;
  final name = '${peer?.firstName ?? ''} ${peer?.lastName ?? ''}'.trim();
  final live = const {'active', 'connected'}.contains(call.status);
  final asCallee = live || call.receiverId == currentUserId;

  context.push(
    Uri(
      path: AppRoutes.outgoingCall,
      queryParameters: {
        'callId': call.id.toString(),
        'recipientId': peerId.toString(),
        'recipientName': name.isEmpty ? 'User' : name,
        if ((peer?.avatarUrl ?? '').isNotEmpty) 'avatarUrl': peer!.avatarUrl!,
        'type': call.isVideoCall ? 'video' : 'voice',
        if (asCallee) 'callee': '1',
      },
    ).toString(),
  );
}
