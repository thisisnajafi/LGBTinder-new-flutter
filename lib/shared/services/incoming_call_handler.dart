import 'package:flutter/material.dart';

import '../../features/calls/data/models/incoming_call_data.dart';
import '../../features/calls/providers/incoming_call_provider.dart';

/// Routes FCM / OneSignal incoming-call payloads into the call coordinator.
class IncomingCallHandler {
  static Map<String, dynamic>? _pendingCallData;

  static void storePendingCallData(Map<String, dynamic> notificationData) {
    _pendingCallData = notificationData;
    IncomingCallBridge.presentIncoming?.call(notificationData);
  }

  static void processPendingCallIfAvailable(BuildContext context) {
    if (_pendingCallData != null) {
      IncomingCallBridge.presentIncoming?.call(_pendingCallData!);
      _pendingCallData = null;
    }
  }

  static void handleIncomingCallNotification(
    Map<String, dynamic> notificationData,
    BuildContext context,
  ) {
    storePendingCallData(notificationData);
  }

  static Map<String, dynamic>? getPendingCallData() {
    final data = _pendingCallData;
    _pendingCallData = null;
    return data;
  }

  static void clearPendingCallData() {
    _pendingCallData = null;
  }

  static bool hasPendingCall() => _pendingCallData != null;

  /// Parse push payload into [IncomingCallData] for tests / debugging.
  static IncomingCallData? parsePayload(Map<String, dynamic> data) {
    return IncomingCallData.fromPayload(data);
  }
}
