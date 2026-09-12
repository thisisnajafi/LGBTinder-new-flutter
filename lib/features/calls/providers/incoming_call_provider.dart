import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../chat/providers/chat_pusher_providers.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/services/agora_service.dart';
import '../../../shared/services/call_permissions.dart';
import '../../../shared/services/chat_pusher_event_names.dart';
import '../../../shared/services/incoming_call_handler.dart';

export '../../../shared/services/incoming_call_handler.dart' show IncomingCallBridge;
import '../data/models/call_action_request.dart';
import '../data/models/incoming_call_data.dart';
import '../data/services/call_kit_service.dart';
import '../../../routes/app_router.dart';
import '../pages/outgoing_call_page.dart';
import '../presentation/widgets/call_permission_sheet.dart';
import '../utils/call_local_busy.dart';
import '../utils/call_navigation.dart';
import '../utils/call_ring_timeout.dart';
import '../utils/call_signaling_log.dart';
import 'active_call_session_provider.dart';
import 'call_provider.dart';
import 'call_providers.dart';
import 'messenger_calls_provider.dart';
import '../../settings/providers/sound_preferences_provider.dart';

/// Active incoming call (in-app banner + CallKit).
final incomingCallProvider =
    NotifierProvider<IncomingCallNotifier, IncomingCallData?>(
  IncomingCallNotifier.new,
);

class IncomingCallNotifier extends Notifier<IncomingCallData?> {
  Timer? _autoDismissTimer;
  IncomingCallData? _pendingNavigation;
  String? _acceptedCallId;
  CallPermissionResult? _blockedPermission;
  bool _blockedPermissionVideo = false;

  @override
  IncomingCallData? build() {
    IncomingCallBridge.presentIncoming = present;
    ref.onDispose(() {
      IncomingCallBridge.presentIncoming = null;
      _autoDismissTimer?.cancel();
      unawaited(SoundService.instance.stopCallSounds());
    });
    return null;
  }

  bool get hasPendingNavigation => _pendingNavigation != null;

  bool get hasBlockedPermission => _blockedPermission != null;

  CallPermissionResult? get blockedPermission => _blockedPermission;

  bool get blockedPermissionVideo => _blockedPermissionVideo;

  void clearBlockedPermission() {
    _blockedPermission = null;
    ref.notifyListeners();
  }

  void _queuePermissionSheet(CallPermissionResult result, {required bool video}) {
    _blockedPermission = result;
    _blockedPermissionVideo = video;
    ref.notifyListeners();
  }

  /// Handle Pusher or push payload.
  void present(Map<String, dynamic> payload) {
    final data = IncomingCallData.fromPayload(payload);
    if (data == null) return;

    if (_acceptedCallId == data.callId ||
        _pendingNavigation?.callId == data.callId) {
      return;
    }

    if (state?.callId == data.callId) return;
    if (_isLocallyBusyFor(data.callId)) {
      unawaited(_postBusy(data.callId));
      return;
    }

    unawaited(SoundService.instance.stopCallSounds());
    state = data;
    unawaited(IncomingCallHandler.persistShow(data));
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(CallRingTimeout.duration, () {
      if (_acceptedCallId == data.callId) return;
      if (state?.callId == data.callId) {
        unawaited(timeoutDismiss());
      }
    });

    if (isAppForeground) {
      unawaited(SoundService.instance.startIncomingRingtone());
    } else {
      unawaited(CallKitService.instance.showIncoming(data));
    }
  }

  bool _isLocallyBusyFor(String incomingCallId) {
    final active = ref.read(callProvider).activeCall;
    final session = ref.read(activeCallSessionProvider);
    return CallLocalBusy.shouldMarkBusy(
      incomingCallId: incomingCallId,
      showingBannerCallId: state?.callId,
      acceptedCallId: _acceptedCallId,
      providerActiveCallId: active?.id,
      providerActiveCallUuid: active?.callId,
      sessionCallId: session?.callId,
      agoraInCall: AgoraService().isInCall,
    );
  }

  Future<void> _postBusy(String callId) async {
    AppLogger.info(
      'Second incoming $callId while busy — POST busy',
      tag: CallSignalingLog.tag,
    );
    try {
      await ref.read(callServiceProvider).markBusy(callId);
    } catch (e) {
      CallSignalingLog.logHttpError('busy', callId, e);
    }
  }

  bool get isAppForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == AppLifecycleState.resumed;
  }

  /// Accept from in-app banner.
  Future<void> accept(BuildContext context) async {
    final data = state;
    if (data == null) return;

    final allowed = await ensureCallMediaPermissions(
      context,
      video: data.isVideo,
    );
    if (!allowed || !context.mounted) return;
    if (state?.callId != data.callId) return;

    _autoDismissTimer?.cancel();

    try {
      final ok = await ref.read(callProvider.notifier).acceptCall(
            CallActionRequest.accept(data.callId),
          );
      if (!ok) {
        AppLogger.error(
          CallSignalingLog.httpError('accept', data.callId),
          tag: CallSignalingLog.tag,
        );
        return;
      }
      state = null;
      unawaited(SoundService.instance.stopCallSounds());
      await CallKitService.instance.endCall(data.callId);

      if (context.mounted) {
        openActiveCallPage(
          context: context,
          callId: int.parse(data.callId),
          recipientId: data.callerId,
          recipientName: data.callerName,
          recipientAvatarUrl: data.callerAvatar,
          type: data.isVideo ? OutgoingCallType.video : OutgoingCallType.voice,
        );
      }
    } catch (e) {
      CallSignalingLog.logHttpError('accept', data.callId, e);
    }
  }

  /// 45s ringing timeout — hide the banner without `POST reject`.
  /// Backend [CheckMissedCall] owns the missed status (CALL-FEAT-003).
  Future<void> timeoutDismiss() async {
    await timeoutDismissFor(state?.callId);
  }

  /// CallKit / banner timeout for a specific id. Never posts reject.
  Future<void> timeoutDismissFor(String? callId) async {
    if (callId == null || callId.isEmpty) return;
    final data = state;
    if (data != null && data.callId != callId) return;

    _autoDismissTimer?.cancel();
    if (data != null && data.callId == callId) {
      state = null;
    }
    unawaited(SoundService.instance.stopCallSounds());
    IncomingCallHandler.clearPendingCallData();
    AppLogger.info(
      'Incoming banner timed out callId=$callId',
      tag: 'IncomingCall',
    );
    await CallKitService.instance.endCall(callId);
  }

  /// Reject from in-app banner.
  Future<void> reject() async {
    final data = state;
    if (data == null) return;

    _autoDismissTimer?.cancel();
    state = null;
    unawaited(SoundService.instance.stopCallSounds());
    IncomingCallHandler.clearPendingCallData();

    try {
      await ref.read(callProvider.notifier).declineCall(
            CallActionRequest.reject(data.callId),
          );
    } catch (e) {
      CallSignalingLog.logHttpError('reject', data.callId, e);
    } finally {
      await CallKitService.instance.endCall(data.callId);
    }
  }

  /// Accept from native CallKit (may lack BuildContext).
  ///
  /// [state] is empty after a killed-app restart — restore from [extras] or
  /// [IncomingCallHandler] / CallKit extras.
  Future<bool> acceptFromCallKit(
    String callId, {
    IncomingCallData? extras,
    bool queueNavigation = true,
  }) async {
    if (_acceptedCallId == callId) {
      // Already accepted (e.g. CallKit replay). Splash owns stack seating when
      // queueNavigation is false — drop any pending Host navigation.
      if (!queueNavigation) {
        _pendingNavigation = null;
      }
      return true;
    }

    var data = extras;
    if (data == null || data.callId != callId) {
      if (state?.callId == callId) {
        data = state;
      } else {
        data = IncomingCallHandler.dataForCallId(callId);
      }
    }
    if (data == null || data.callId != callId) {
      final persisted = await IncomingCallHandler.loadPersisted();
      if (persisted?.data.callId == callId) {
        data = persisted!.data;
      }
    }
    if (data == null || data.callId != callId) {
      AppLogger.warning(
        'acceptFromCallKit: no payload for $callId',
        tag: 'IncomingCall',
      );
      return false;
    }

    final permission = await CallPermissions.ensure(video: data.isVideo);
    if (permission != CallPermissionResult.granted) {
      AppLogger.warning(
        'acceptFromCallKit blocked by permission=$permission',
        tag: 'IncomingCall',
      );
      _acceptedCallId = null;
      _queuePermissionSheet(permission, video: data.isVideo);
      return false;
    }

    _acceptedCallId = callId;
    _autoDismissTimer?.cancel();
    unawaited(IncomingCallHandler.markAccepted(data));

    try {
      var ok = await ref.read(callProvider.notifier).acceptCall(
            CallActionRequest.accept(callId),
          );
      if (!ok) {
        ok = await _canJoinExistingCall(callId);
      }
      if (!ok) {
        AppLogger.error(
          CallSignalingLog.httpError('accept', callId),
          tag: CallSignalingLog.tag,
        );
        _acceptedCallId = null;
        return false;
      }
      state = null;
      unawaited(SoundService.instance.stopCallSounds());
      if (queueNavigation) {
        _pendingNavigation = data;
      } else {
        // Splash owns navigation — clear native/prefs so hangup can't re-restore.
        IncomingCallHandler.clearPendingCallData();
        unawaited(CallKitService.instance.endCall(callId));
      }
      return true;
    } catch (e) {
      CallSignalingLog.logHttpError('accept', callId, e);
      final canJoin = await _canJoinExistingCall(callId);
      if (!canJoin) {
        _acceptedCallId = null;
        return false;
      }
      state = null;
      unawaited(SoundService.instance.stopCallSounds());
      if (queueNavigation) {
        _pendingNavigation = data;
      } else {
        IncomingCallHandler.clearPendingCallData();
        unawaited(CallKitService.instance.endCall(callId));
      }
      return true;
    }
  }

  Future<bool> _canJoinExistingCall(String callId) async {
    try {
      final call = await ref.read(callProvider.notifier).getCall(callId);
      final status = call.status.toLowerCase();
      return status == 'active' ||
          status == 'connected' ||
          status == 'accepted' ||
          status == 'ringing' ||
          status == 'initiating';
    } catch (e) {
      AppLogger.warning(
        'getCall join-check failed',
        tag: 'IncomingCall',
        error: e,
      );
      return false;
    }
  }

  /// Decline from native CallKit, including killed-app / lock-screen
  /// when [state] is null. Always `POST /calls/{id}/reject` unless this
  /// call was already accepted.
  Future<void> rejectFromCallKit(String callId) async {
    if (_acceptedCallId == callId) {
      AppLogger.info(
        'rejectFromCallKit skipped; already accepted $callId',
        tag: 'IncomingCall',
      );
      return;
    }
    if (state?.callId == callId) {
      await reject();
      return;
    }

    _autoDismissTimer?.cancel();
    unawaited(SoundService.instance.stopCallSounds());
    AppLogger.info(
      'rejectFromCallKit posting reject for $callId (state=${state?.callId})',
      tag: 'IncomingCall',
    );

    try {
      await ref.read(callProvider.notifier).declineCall(
            CallActionRequest.reject(callId),
          );
      final parsed = int.tryParse(callId) ?? 0;
      if (parsed > 0) {
        ref.read(messengerCallsProvider.notifier).applyRemoteStatus(
              callId: parsed,
              status: 'rejected',
            );
      }
    } catch (e) {
      CallSignalingLog.logHttpError('reject', callId, e);
    } finally {
      IncomingCallHandler.clearPendingCallData();
      await CallKitService.instance.endCall(callId);
    }
  }

  /// Native notification tap while a call is already live.
  /// Does not accept or join again — IncomingCallHost re-opens the route.
  Future<void> callbackFromCallKit(String callId) async {
    AppLogger.info('CallKit callback $callId', tag: 'IncomingCall');
    if (!AgoraService().isInCall) {
      return;
    }
    if (_pendingNavigation?.callId == callId) {
      return;
    }
    var data = IncomingCallHandler.dataForCallId(callId);
    if (data == null || data.callId != callId) {
      final persisted = await IncomingCallHandler.loadPersisted();
      if (persisted?.data.callId == callId) {
        data = persisted!.data;
      }
    }
    if (data == null || data.callId != callId) {
      return;
    }
    _pendingNavigation = data;
    ref.notifyListeners();
  }

  /// Caller hung up / call finished — stop ringtone and hide the banner.
  /// Does not call decline/end APIs (the remote side already did).
  Future<void> dismissRemote(String callId) async {
    final data = state;
    if (data == null || data.callId != callId) {
      await CallKitService.instance.endCall(callId);
      return;
    }

    _autoDismissTimer?.cancel();
    state = null;
    unawaited(SoundService.instance.stopCallSounds());
    await CallKitService.instance.endCall(callId);
  }

  /// Navigate after CallKit accept when context becomes available.
  /// Skips splash so [context.go] from startup cannot drop the call route.
  void consumePendingNavigation(BuildContext context) {
    final data = _pendingNavigation;
    if (data == null) return;
    if (!context.mounted) return;

    try {
      final uri =
          GoRouter.of(context).routerDelegate.currentConfiguration.uri;
      if (uri.path == AppRoutes.splash || uri.path.isEmpty) {
        return;
      }
      if (uri.path == AppRoutes.outgoingCall &&
          uri.queryParameters['callId'] == data.callId) {
        _pendingNavigation = null;
        return;
      }
    } catch (e) {
      AppLogger.warning(
        'consumePendingNavigation route check failed',
        tag: 'IncomingCall',
        error: e,
      );
      return;
    }

    _pendingNavigation = null;
    IncomingCallHandler.clearPendingCallData();

    openActiveCallPage(
      context: context,
      callId: int.parse(data.callId),
      recipientId: data.callerId,
      recipientName: data.callerName,
      recipientAvatarUrl: data.callerAvatar,
      type: data.isVideo ? OutgoingCallType.video : OutgoingCallType.voice,
    );
  }
}

/// Subscribes to Pusher call events while the user is logged in.
final incomingCallListenerProvider = Provider<void>((ref) {
  final pusher = ref.watch(pusherWebSocketServiceProvider);

  final sub = pusher.callEventStream.listen((event) {
    final payload = event.payload;
    final callId = IncomingCallData.callIdFromPayload(payload);
    switch (event.name) {
      case ChatPusherEventNames.callIncoming:
        final parsedIncoming = int.tryParse(callId ?? '');
        if (parsedIncoming != null && parsedIncoming > 0) {
          unawaited(pusher.subscribeCall(parsedIncoming));
        }
        ref.read(incomingCallProvider.notifier).present(payload);
        ref.read(messengerCallsProvider.notifier).refreshOnIncoming();
        return;
      case ChatPusherEventNames.callEnded:
      case ChatPusherEventNames.callRejected:
      case ChatPusherEventNames.callBusy:
        if (callId != null) {
          final parsed = int.tryParse(callId);
          if (parsed != null && parsed > 0) {
            unawaited(pusher.unsubscribeCall(parsed));
          }
          unawaited(ref.read(incomingCallProvider.notifier).dismissRemote(callId));
        }
        ref.read(messengerCallsProvider.notifier).applyRemoteStatus(
              callId: int.tryParse(callId ?? '') ?? 0,
              status: payload['status']?.toString() ??
                  (event.name == ChatPusherEventNames.callRejected
                      ? 'rejected'
                      : event.name == ChatPusherEventNames.callBusy
                          ? 'busy'
                          : 'ended'),
            );
        return;
      case ChatPusherEventNames.callAccepted:
        ref.read(messengerCallsProvider.notifier).applyRemoteStatus(
              callId: int.tryParse(callId ?? '') ?? 0,
              status: payload['status']?.toString() ?? 'active',
            );
        return;
    }
  });

  ref.onDispose(sub.cancel);
});
