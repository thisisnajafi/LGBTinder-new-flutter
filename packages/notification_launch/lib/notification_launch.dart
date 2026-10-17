import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Request code for the tap [PendingIntent].
///
/// Matches `LaunchIntents.requestCode` (32-bit wrap). A different id or tag
/// must not reuse the previous extras.
int notificationLaunchRequestCode(int id, String? tag) {
  var code = id;
  if (tag != null && tag.isNotEmpty) {
    code = _i32((code * 31) ^ tag.length);
    for (final unit in tag.codeUnits) {
      code = _i32((code * 31) + unit);
    }
  }
  return _i32(code);
}

int _i32(int value) => value.toSigned(32);

/// Android side of a notification tap that must survive a warm process.
class NotificationLaunch {
  NotificationLaunch._();

  static const MethodChannel _channel = MethodChannel(
    'com.lgbtfinder/notification_launch',
  );

  /// Replaces the tray row's content intent so the tap launches MainActivity
  /// with [payload] (unique request code, UPDATE_CURRENT | IMMUTABLE).
  static Future<void> bindTapIntent({
    required int id,
    String? tag,
    required String payload,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('bindTapIntent', {
        'id': id,
        'tag': tag,
        'payload': payload,
      });
    } catch (e) {
      debugPrint('[LaunchRoute] bind failed: $e');
    }
  }

  /// Payload stashed from MainActivity.onCreate / onNewIntent, then cleared.
  static Future<String?> takePayload() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('takePayload');
    } catch (e) {
      debugPrint('[LaunchRoute] takePayload failed: $e');
      return null;
    }
  }
}
