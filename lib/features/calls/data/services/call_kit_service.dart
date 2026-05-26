import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../models/incoming_call_data.dart';
import '../../../settings/providers/sound_preferences_provider.dart';

typedef CallKitActionHandler = Future<void> Function(String callId);

/// Native CallKit / Android full-screen incoming call UI.
class CallKitService {
  CallKitService._();

  static final CallKitService instance = CallKitService._();

  StreamSubscription<dynamic>? _eventSub;
  CallKitActionHandler? _onAccept;
  CallKitActionHandler? _onDecline;
  bool _initialized = false;

  /// Wire accept/decline callbacks (call once after login).
  Future<void> initialize({
    required CallKitActionHandler onAccept,
    required CallKitActionHandler onDecline,
  }) async {
    if (_initialized) return;
    _onAccept = onAccept;
    _onDecline = onDecline;

    _eventSub = FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      final body = event.body;
      if (body is! Map) return;

      final callId = (body['id'] ?? body['callId'] ?? body['uuid'])?.toString();
      if (callId == null || callId.isEmpty) return;

      switch (event.event) {
        case Event.actionCallAccept:
          await _onAccept?.call(callId);
        case Event.actionCallDecline:
        case Event.actionCallTimeout:
        case Event.actionCallEnded:
          await _onDecline?.call(callId);
        default:
          break;
      }
    });

    _initialized = true;
    debugPrint('CallKitService initialized');
  }

  /// Show native incoming call UI.
  Future<void> showIncoming(IncomingCallData data) async {
    if (!_initialized) {
      debugPrint('CallKitService: showIncoming skipped — not initialized');
      return;
    }

    final ringtone = SoundService.instance.getCallRingtonePath();

    final params = CallKitParams(
      id: data.callId,
      nameCaller: data.callerName,
      appName: 'LGBTFinder',
      avatar: data.callerAvatar ?? '',
      handle: data.callId,
      type: data.isVideo ? 1 : 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: 45000,
      extra: <String, dynamic>{
        'callId': data.callId,
        'callerId': data.callerId,
        'callType': data.callType,
      },
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: ringtone,
        backgroundColor: '#111827',
        actionColor: '#10B981',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        ringtonePath: ringtone,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> endCall(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('CallKitService.endCall: $e');
    }
  }

  void dispose() {
    _eventSub?.cancel();
    _eventSub = null;
    _initialized = false;
  }
}
