import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/app_logger.dart';
import '../../features/calls/data/models/incoming_call_data.dart';

/// Bridge for non-Riverpod services (FCM push handler).
class IncomingCallBridge {
  static void Function(Map<String, dynamic> payload)? presentIncoming;
}

/// Restored incoming-call payload plus whether the user already accepted natively.
class IncomingCallRestore {
  final IncomingCallData data;
  final bool accepted;

  const IncomingCallRestore({
    required this.data,
    required this.accepted,
  });
}

/// Routes FCM / OneSignal incoming-call payloads into the call coordinator.
/// Persists the last payload so a killed-app Accept can restore it.
class IncomingCallHandler {
  static const _tag = 'IncomingCallHandler';
  static const _prefsPayloadKey = 'lgbtfinder_pending_incoming_call';
  static const _prefsAcceptedKey = 'lgbtfinder_pending_incoming_accepted';

  static Map<String, dynamic>? _pendingCallData;
  static bool _accepted = false;
  static String? _acceptedCallId;

  static bool get wasAccepted => _accepted;
  static String? get acceptedCallId => _acceptedCallId;

  static bool wasCallAccepted(String callId) =>
      _accepted && _acceptedCallId == callId;

  static void storePendingCallData(Map<String, dynamic> notificationData) {
    _pendingCallData = notificationData;
    final parsed = IncomingCallData.fromPayload(notificationData);
    if (parsed != null) {
      persistShow(parsed);
    }
    if (_accepted && _acceptedCallId != null) {
      final incomingId = IncomingCallData.callIdFromPayload(notificationData);
      if (incomingId == _acceptedCallId) {
        return;
      }
    }
    IncomingCallBridge.presentIncoming?.call(notificationData);
  }

  static void processPendingCallIfAvailable(BuildContext context) {
    final data = _pendingCallData;
    if (data == null) return;
    if (_accepted) {
      return;
    }
    IncomingCallBridge.presentIncoming?.call(data);
    _pendingCallData = null;
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
    _accepted = false;
    _acceptedCallId = null;
    persistClear();
  }

  static bool hasPendingCall() => _pendingCallData != null && !_accepted;

  /// Parse push payload into [IncomingCallData] for tests / debugging.
  static IncomingCallData? parsePayload(Map<String, dynamic> data) {
    return IncomingCallData.fromPayload(data);
  }

  static Future<void> persistShow(IncomingCallData data) async {
    _pendingCallData = data.toExtras();
    if (_acceptedCallId != data.callId) {
      _accepted = false;
      _acceptedCallId = null;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsPayloadKey, jsonEncode(data.toExtras()));
      if (_acceptedCallId != data.callId) {
        await prefs.setBool(_prefsAcceptedKey, false);
      }
    } catch (e) {
      AppLogger.warning('persistShow prefs failed', tag: _tag, error: e);
    }
  }

  static Future<void> markAccepted(IncomingCallData data) async {
    _pendingCallData = data.toExtras();
    _accepted = true;
    _acceptedCallId = data.callId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsPayloadKey, jsonEncode(data.toExtras()));
      await prefs.setBool(_prefsAcceptedKey, true);
    } catch (e) {
      AppLogger.warning('markAccepted prefs failed', tag: _tag, error: e);
    }
  }

  static Future<void> persistClear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsPayloadKey);
      await prefs.remove(_prefsAcceptedKey);
    } catch (e) {
      AppLogger.warning('persistClear prefs failed', tag: _tag, error: e);
    }
  }

  static IncomingCallData? dataForCallId(String callId) {
    final pending = _pendingCallData;
    if (pending == null) return null;
    final data = IncomingCallData.fromPayload(pending) ??
        IncomingCallData.fromCallKitMap(pending);
    if (data?.callId == callId) return data;
    return null;
  }

  static Future<IncomingCallRestore?> loadPersisted() async {
    final memory = _pendingCallData;
    if (memory != null) {
      final data = IncomingCallData.fromPayload(memory) ??
          IncomingCallData.fromCallKitMap(memory);
      if (data != null) {
        return IncomingCallRestore(data: data, accepted: _accepted);
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsPayloadKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final data =
          IncomingCallData.fromPayload(map) ?? IncomingCallData.fromCallKitMap(map);
      if (data == null) return null;
      final accepted = prefs.getBool(_prefsAcceptedKey) ?? false;
      _pendingCallData = map;
      _accepted = accepted;
      _acceptedCallId = accepted ? data.callId : null;
      return IncomingCallRestore(data: data, accepted: accepted);
    } catch (e) {
      AppLogger.warning('loadPersisted prefs failed', tag: _tag, error: e);
      return null;
    }
  }
}
