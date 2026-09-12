import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_router.dart';
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

/// Leaves the call screen safely after hangup / reject / failure.
///
/// Cold-start Accept can stack the call on Splash. A bare [pop] then reveals a
/// dead Splash (`_redirected` already true) and the UI never recovers. Prefer
/// [pop] when a real parent exists; otherwise (or if Splash is underneath)
/// [go] home.
void leaveCallRoute(BuildContext context, {String? callId}) {
  if (callId != null && callId.isNotEmpty) {
    unawaited(CallKitService.instance.endCall(callId));
    IncomingCallHandler.clearPendingCallData();
  }
  if (!context.mounted) return;

  final router = GoRouter.of(context);
  final underIsSplash = _stackContainsSplash(router);

  if (context.canPop() && !underIsSplash) {
    context.pop();
    return;
  }

  router.go(AppRoutes.home);
}

/// Re-opens the live call screen without joining Agora again.
void restoreActiveCallRoute(GoRouter router, ActiveCallSession session) {
  final uri = router.routerDelegate.currentConfiguration.uri;
  if (ActiveCallLifecycle.isCurrentCallRoute(
    path: uri.path,
    callIdQuery: uri.queryParameters['callId'],
    sessionCallId: session.callId,
  )) {
    return;
  }
  router.push(session.routeLocation);
}

bool _stackContainsSplash(GoRouter router) {
  try {
    final matches = router.routerDelegate.currentConfiguration.matches;
    for (final match in matches) {
      final loc = match.matchedLocation;
      if (loc == AppRoutes.splash || loc == '/') {
        return true;
      }
    }
    return router.routerDelegate.currentConfiguration.uri.path ==
        AppRoutes.splash;
  } catch (_) {
    return false;
  }
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
  context.push(
    activeCallLocation(
      callId: callId,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientAvatarUrl: recipientAvatarUrl,
      type: type,
    ),
  );
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
