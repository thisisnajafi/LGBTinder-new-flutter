import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/services/incoming_call_channel.dart';
import '../../../../shared/services/incoming_call_handler.dart';
import '../../../../shared/services/notification_navigation.dart';
import '../../../../shared/services/pending_launch_route.dart';
import '../models/call_kit_restore.dart';
import '../models/incoming_call_data.dart';
import '../../../settings/providers/sound_preferences_provider.dart';
import '../../../../shared/services/background_auth_store.dart';
import '../../../../shared/services/token_storage_service.dart';
import '../../utils/background_callkit_show.dart';
import '../../utils/call_permission_lifecycle.dart';
import '../../utils/call_ring_timeout.dart';
import 'call_kit_event_action.dart';
import 'callkit_pending_flusher.dart';
import 'callkit_terminal_request.dart';

typedef CallKitActionHandler = Future<void> Function(String callId);

class _CallKitResumeFlush extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(flushStoredCallKitActions());
    }
  }
}

class _QueuedCallKitAction {
  final CallKitEventAction action;
  final String callId;

  const _QueuedCallKitAction(this.action, this.callId);
}

/// Native CallKit / Android full-screen incoming call UI.
class CallKitService {
  static const _tag = 'CallKit';

  CallKitService._();

  static final CallKitService instance = CallKitService._();

  StreamSubscription<dynamic>? _eventSub;
  CallKitActionHandler? _onAccept;
  CallKitActionHandler? _onDecline;
  CallKitActionHandler? _onCallback;
  CallKitActionHandler? _onTimeout;
  bool _listening = false;
  bool _handlersAttached = false;
  final List<_QueuedCallKitAction> _queued = [];
  final _CallKitResumeFlush _resumeFlush = _CallKitResumeFlush();

  /// Start the native event stream before splash / Riverpod handlers exist.
  Future<void> startListening() async {
    if (_listening) return;
    _eventSub = FlutterCallkitIncoming.onEvent.listen(_onNativeEvent);
    _listening = true;
    WidgetsBinding.instance.addObserver(_resumeFlush);
    await markCallKitDartListening(true);
    AppLogger.info('Listening for native events', tag: _tag);
  }

  /// Wire accept/decline/callback/timeout. Replays queued cold-start events.
  Future<void> initialize({
    required CallKitActionHandler onAccept,
    required CallKitActionHandler onDecline,
    CallKitActionHandler? onCallback,
    CallKitActionHandler? onTimeout,
  }) async {
    await startListening();
    final firstAttach = !_handlersAttached;
    _onAccept = onAccept;
    _onDecline = onDecline;
    _onCallback = onCallback;
    _onTimeout = onTimeout;
    _handlersAttached = true;
    await _flushQueued();
    if (firstAttach) {
      await _replayAcceptedActiveCall();
    }
    AppLogger.info('Handlers attached', tag: _tag);
  }

  Future<void> _onNativeEvent(CallEvent? event) async {
    if (event == null) return;
    final body = event.body;
    if (body is! Map) return;

    final parsed =
        IncomingCallData.fromCallKitMap(Map<dynamic, dynamic>.from(body));
    final callId = parsed?.callId ??
        (body['id'] ?? body['callId'] ?? body['uuid'])?.toString();
    if (callId == null || callId.isEmpty) return;

    final action = classifyCallKitEvent(event.event);
    AppLogger.info(
      'Native event=${event.event} action=$action callId=$callId',
      tag: _tag,
    );

    switch (action) {
      case CallKitEventAction.accept:
        if (parsed != null) {
          unawaited(IncomingCallHandler.markAccepted(parsed));
        }
        await _dispatch(CallKitEventAction.accept, callId);
      case CallKitEventAction.decline:
        if (!CallPermissionLifecycle.shouldPostDecline(
          permissionRequestInFlight:
              CallPermissionLifecycle.blocksCallTerminalActions,
        )) {
          AppLogger.info(
            'Ignoring decline during permission dialog callId=$callId',
            tag: _tag,
          );
          await dropCallKitPending(callId);
          break;
        }
        await enqueueCallKitPending(
          CallKitPendingAction(
            callId: callId,
            kind: CallKitPendingKind.decline,
            recordedAt: DateTime.now(),
          ),
        );
        await _dispatch(CallKitEventAction.decline, callId);
        if (_onDecline == null) {
          unawaited(flushStoredCallKitActions());
        }
      case CallKitEventAction.timeout:
        AppLogger.info(
          'Timeout $callId is not stored as a decline; the server ring timeout marks it missed',
          tag: _tag,
        );
        IncomingCallHandler.clearPendingCallData();
        unawaited(endCall(callId));
        if (_onTimeout != null) {
          await _onTimeout!(callId);
        }
      case CallKitEventAction.callback:
        final target = parsed ?? await _storedCall(callId);
        if (target != null && target.callerId > 0) {
          PendingLaunchRoute.store(
            NotificationNavigation.callBackPayload(
              userId: target.callerId,
              userName: target.callerName,
              callType: target.callType,
              avatarUrl: target.callerAvatar,
            ),
          );
        }
        await _dispatch(CallKitEventAction.callback, callId);
      case CallKitEventAction.dismissOnly:
        AppLogger.info('Ended $callId (UI dismiss only)', tag: _tag);
      case CallKitEventAction.ignore:
        break;
    }
  }

  Future<IncomingCallData?> _storedCall(String callId) async {
    final persisted = await IncomingCallHandler.loadPersisted();
    if (persisted != null && persisted.data.callId == callId) {
      return persisted.data;
    }
    return null;
  }

  Future<void> _dispatch(CallKitEventAction action, String callId) async {
    final handler = switch (action) {
      CallKitEventAction.accept => _onAccept,
      CallKitEventAction.decline => _onDecline,
      CallKitEventAction.callback => _onCallback,
      _ => null,
    };
    if (handler == null) {
      if (action == CallKitEventAction.accept ||
          action == CallKitEventAction.decline ||
          action == CallKitEventAction.callback) {
        _queued.add(_QueuedCallKitAction(action, callId));
      }
      return;
    }
    await handler(callId);
  }

  Future<void> _flushQueued() async {
    if (_queued.isEmpty) return;
    final pending = List<_QueuedCallKitAction>.from(_queued);
    _queued.clear();
    for (final item in pending) {
      await _dispatch(item.action, item.callId);
    }
  }

  Future<void> _replayAcceptedActiveCall() async {
    final accepted = await restoreAcceptedCall();
    if (accepted == null) return;
    await _dispatch(CallKitEventAction.accept, accepted.callId);
  }

  /// Last CallKit row the user already answered (killed-app Accept).
  /// Prefers the newest accepted call and dismisses older zombie CallKit rows.
  Future<IncomingCallData?> restoreAcceptedCall() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List) {
        final picked = CallKitRestore.pick(calls);
        for (final id in picked.staleIds) {
          unawaited(endCall(id));
        }
        if (picked.accepted != null) {
          unawaited(IncomingCallHandler.markAccepted(picked.accepted!));
          return picked.accepted;
        }
      }
    } catch (e) {
      AppLogger.warning('restoreAcceptedCall failed', tag: _tag, error: e);
    }

    final persisted = await IncomingCallHandler.loadPersisted();
    if (persisted != null && persisted.accepted) {
      return persisted.data;
    }
    return null;
  }

  /// Unanswered CallKit row that is still ringing. Not ended on launch.
  Future<IncomingCallData?> currentRingingCall() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List) {
        final ringing = CallKitRestore.pick(calls).ringing;
        if (ringing != null) return ringing;
      }
    } catch (e) {
      AppLogger.warning('currentRingingCall failed', tag: _tag, error: e);
    }

    final persisted = await IncomingCallHandler.loadPersisted();
    if (persisted != null && !persisted.accepted) {
      return persisted.data;
    }
    return null;
  }

  /// Show native incoming call UI.
  Future<void> showIncoming(IncomingCallData data) async {
    unawaited(_mirrorAuthForKilledDecline());
    unawaited(IncomingCallHandler.persistShow(data));
    String? ringtone;
    try {
      ringtone = SoundService.instance.getCallRingtonePath();
    } catch (e) {
      AppLogger.warning('Ringtone path failed', tag: _tag, error: e);
    }
    if (ringtone == null || ringtone.isEmpty) {
      AppLogger.warning('Ringtone asset missing', tag: _tag);
      ringtone = null;
    }

    final avatar = data.callerAvatar;
    await IncomingCallChannel.ensure();
    final params = buildIncomingCallKitParams(
      data: data,
      ringtone: ringtone,
      avatar: (avatar != null && avatar.isNotEmpty) ? avatar : null,
      backgroundColor: _hex(AppColors.backgroundDark),
      actionColor: _hex(AppColors.primaryLight),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      await IncomingCallChannel.ensure();
    } catch (e) {
      AppLogger.warning('showCallkitIncoming failed', tag: _tag, error: e);
    }
  }

  /// Show CallKit from an FCM background isolate (no Riverpod / login wiring).
  ///
  /// The banner is shown before any secure-storage read. Waiting on the
  /// keystore in this isolate hangs while the main process is alive, so the
  /// incoming call times out with no banner (RT-016). The token is already
  /// mirrored at login for a killed-app decline (RT-013).
  static Future<void> showIncomingFromIsolate(IncomingCallData data) async {
    final terminalIds = await _terminalCallIds();
    if (!BackgroundCallKitShow.shouldShow(
      callId: data.callId,
      terminalCallIds: terminalIds,
      permissionRequestInFlight: CallPermissionLifecycle.requestInFlight,
    )) {
      AppLogger.info(
        'Skipped background CallKit callId=${data.callId}',
        tag: _tag,
      );
      return;
    }
    await instance.showIncoming(data);
    unawaited(_mirrorAuthForKilledDecline());
  }

  /// Decline/timeout rows already stored. A different call id still rings.
  static Future<Set<String>> _terminalCallIds() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 1),
      );
      return decodeCallKitPending(prefs.getString(kCallkitPendingActionsKey))
          .map((action) => action.callId)
          .toSet();
    } catch (e) {
      AppLogger.warning(
        'Pending CallKit ids unreadable; showing the banner',
        tag: _tag,
        error: e,
      );
      return const {};
    }
  }

  /// Bearer token must be on disk before the process can be killed again.
  static Future<void> _mirrorAuthForKilledDecline() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 1),
      );
      final mirrored = prefs.getString(kBackgroundAuthTokenKey);
      if (mirrored != null && mirrored.isNotEmpty) return;
      final token = await TokenStorageService().getAuthToken().timeout(
        const Duration(seconds: 2),
      );
      await BackgroundAuthStore.mirror(token);
    } catch (e) {
      AppLogger.warning('Auth mirror for CallKit failed', tag: _tag, error: e);
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      AppLogger.warning('endCall failed', tag: _tag, error: e);
    }
  }

  /// Dismiss every native CallKit row (stale cold-start leftovers).
  Future<void> endAllCalls() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      AppLogger.warning('endAllCalls failed', tag: _tag, error: e);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(_resumeFlush);
    _eventSub?.cancel();
    _eventSub = null;
    _listening = false;
    _handlersAttached = false;
    _onAccept = null;
    _onDecline = null;
    _onCallback = null;
    _onTimeout = null;
    _queued.clear();
    unawaited(markCallKitDartListening(false));
  }

  static String _hex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

/// Native incoming-call UI. High-importance channel, full-screen intent, and
/// a missed-call action that stays on the notification.
CallKitParams buildIncomingCallKitParams({
  required IncomingCallData data,
  required String? ringtone,
  required String? avatar,
  required String backgroundColor,
  required String actionColor,
}) {
  return CallKitParams(
    id: data.callId,
    nameCaller: data.callerName,
    appName: 'LGBTFinder',
    avatar: avatar,
    handle: data.callKitSubtitle,
    type: data.isVideo ? 1 : 0,
    textAccept: 'Accept',
    textDecline: 'Decline',
    duration: CallRingTimeout.milliseconds,
    extra: data.toExtras(),
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: true,
      callbackText: 'Call back',
    ),
    android: AndroidParams(
      isCustomNotification: true,
      isShowFullLockedScreen: true,
      isImportant: true,
      isShowLogo: false,
      ringtonePath: ringtone,
      backgroundColor: backgroundColor,
      actionColor: actionColor,
      textColor: '#FFFFFF',
      incomingCallNotificationChannelName: 'Incoming Calls',
      missedCallNotificationChannelName: 'Missed Calls',
    ),
    ios: IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: data.isVideo,
      ringtonePath: ringtone,
    ),
  );
}
