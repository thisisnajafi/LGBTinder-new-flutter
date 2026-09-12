import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/services/incoming_call_handler.dart';
import '../models/call_kit_restore.dart';
import '../models/incoming_call_data.dart';
import '../../../settings/providers/sound_preferences_provider.dart';
import '../../utils/call_ring_timeout.dart';
import 'call_kit_event_action.dart';

typedef CallKitActionHandler = Future<void> Function(String callId);

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

  /// Start the native event stream before splash / Riverpod handlers exist.
  Future<void> startListening() async {
    if (_listening) return;
    _eventSub = FlutterCallkitIncoming.onEvent.listen(_onNativeEvent);
    _listening = true;
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
        await _dispatch(CallKitEventAction.decline, callId);
      case CallKitEventAction.timeout:
        IncomingCallHandler.clearPendingCallData();
        unawaited(endCall(callId));
        AppLogger.info(
          'Timeout $callId dismissed without reject',
          tag: _tag,
        );
        if (_onTimeout != null) {
          await _onTimeout!(callId);
        }
      case CallKitEventAction.callback:
        await _dispatch(CallKitEventAction.callback, callId);
      case CallKitEventAction.dismissOnly:
        AppLogger.info('Ended $callId (UI dismiss only)', tag: _tag);
      case CallKitEventAction.ignore:
        break;
    }
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

  /// Show native incoming call UI.
  Future<void> showIncoming(IncomingCallData data) async {
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
    final params = CallKitParams(
      id: data.callId,
      nameCaller: data.callerName,
      appName: 'LGBTFinder',
      avatar: (avatar != null && avatar.isNotEmpty) ? avatar : null,
      handle: data.isVideo ? 'Video Call' : 'Voice Call',
      type: data.isVideo ? 1 : 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: CallRingTimeout.milliseconds,
      extra: data.toExtras(),
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: ringtone,
        backgroundColor: _hex(AppColors.backgroundDark),
        actionColor: _hex(AppColors.feedbackSuccess),
        textColor: _hex(AppColors.textPrimaryDark),
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo', // ios/Runner/Assets.xcassets/CallKitLogo
        handleType: 'generic',
        supportsVideo: data.isVideo,
        ringtonePath: ringtone,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Show CallKit from an FCM background isolate (no Riverpod / login wiring).
  static Future<void> showIncomingFromIsolate(IncomingCallData data) async {
    await IncomingCallHandler.persistShow(data);
    await instance.showIncoming(data);
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
    _eventSub?.cancel();
    _eventSub = null;
    _listening = false;
    _handlersAttached = false;
    _onAccept = null;
    _onDecline = null;
    _onCallback = null;
    _queued.clear();
  }

  static String _hex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
