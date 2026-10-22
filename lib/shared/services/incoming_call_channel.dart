import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/services/app_logger.dart';

/// Keeps the CallKit incoming channel at max importance with a ringtone.
///
/// The plugin recreates `callkit_incoming_channel_id`. If an older install
/// left that channel below high importance, Android will not raise it, and
/// the call stays in the shade with no heads-up.
class IncomingCallChannel {
  IncomingCallChannel._();

  static const MethodChannel _channel = MethodChannel(
    'com.lgbtfinder/incoming_call_alerts',
  );

  static Future<void> ensure() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('ensure');
    } catch (e) {
      AppLogger.warning(
        'Incoming call channel ensure failed',
        tag: 'CallKit',
        error: e,
      );
    }
  }
}
