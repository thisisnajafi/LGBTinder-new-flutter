import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Route saved when a notification opens a terminated app.
///
/// Splash replaces the stack with Discover after session restore. The tap has
/// to wait until that redirect, or the chat (or call back) is dropped.
class PendingLaunchRoute {
  PendingLaunchRoute._();

  static Map<String, dynamic>? _payload;
  static bool navigationReady = false;
  static bool initialMessageCaptured = false;
  static bool localLaunchCaptured = false;
  static String? _consumedSignature;
  static DateTime? _consumedAt;
  static Completer<void>? _settled;

  /// Completes after the cold-start FCM and local-notification reads finish.
  static Future<void> get settled {
    final pending = _settled;
    if (pending != null) return pending.future;
    return Future<void>.value();
  }

  static bool get hasPayload => _payload != null;

  @visibleForTesting
  static void reset() {
    _payload = null;
    navigationReady = false;
    initialMessageCaptured = false;
    localLaunchCaptured = false;
    _consumedSignature = null;
    _consumedAt = null;
    _settled = null;
  }

  static void markNavigationReady() {
    navigationReady = true;
  }

  /// Starts a capture. Splash waits on [settled] before it leaves `/`.
  static Future<void> capture(
    Future<void> Function() read,
  ) {
    final completer = _settled ??= Completer<void>();
    return read().whenComplete(() {
      if (!completer.isCompleted) completer.complete();
    });
  }

  static void store(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return;
    final copy = Map<String, dynamic>.from(data);
    final type = copy['type']?.toString() ?? '';
    if (type.isEmpty) return;
    if (_recentlyConsumed(copy)) return;
    final current = _payload;
    if (current != null && _rank(copy) < _rank(current)) return;
    _payload = copy;
  }

  /// True when splash just opened this same notification.
  static bool wasJustConsumed(Map<String, dynamic>? data) {
    if (data == null) return false;
    return _recentlyConsumed(data);
  }

  static Map<String, dynamic>? peek() {
    final payload = _payload;
    if (payload == null) return null;
    return Map<String, dynamic>.from(payload);
  }

  static Map<String, dynamic>? consume() {
    final payload = _payload;
    _payload = null;
    if (payload == null) return null;
    _consumedSignature = _signature(payload);
    _consumedAt = DateTime.now();
    return Map<String, dynamic>.from(payload);
  }

  /// Local notification that launched a terminated process.
  static Map<String, dynamic>? payloadFromLocalLaunch({
    required bool didLaunchApp,
    String? payload,
    String? actionId,
  }) {
    if (!didLaunchApp) return null;
    final parsed = _decode(payload);
    if (parsed == null) return null;
    final action = actionId?.trim() ?? '';
    if (action.isNotEmpty) {
      parsed['action'] = action;
    }
    return parsed;
  }

  /// FCM [FirebaseMessaging.getInitialMessage] data map.
  static Map<String, dynamic>? payloadFromFcmData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;
    final copy = Map<String, dynamic>.from(data);
    final type = copy['type']?.toString();
    if (type == 'chat' || type == 'new_message') {
      copy['type'] = 'message';
    }
    if (copy['type'] == null || copy['type'].toString().isEmpty) return null;
    return copy;
  }

  static int _rank(Map<String, dynamic> data) {
    if (data['action']?.toString() == 'call_back') return 3;
    final type = data['type']?.toString() ?? '';
    if (type == 'message' || type == 'chat' || type == 'new_message') return 2;
    return 1;
  }

  static bool _recentlyConsumed(Map<String, dynamic> data) {
    final at = _consumedAt;
    final signature = _consumedSignature;
    if (at == null || signature == null) return false;
    if (DateTime.now().difference(at) > const Duration(seconds: 3)) {
      return false;
    }
    return _signature(data) == signature;
  }

  static String _signature(Map<String, dynamic> data) {
    return '${data['action']}|${data['type']}|${data['user_id']}|${data['sender_id']}|${data['message_id']}|${data['call_id']}';
  }

  static Map<String, dynamic>? _decode(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
