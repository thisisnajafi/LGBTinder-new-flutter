import 'package:flutter/services.dart';

/// Enables Android FLAG_SECURE to block screenshots/recording on sensitive screens.
class ScreenshotProtection {
  ScreenshotProtection._();

  static const MethodChannel _channel =
      MethodChannel('com.lgbtfinder/screenshot_protection');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod<void>('enable');
    } on MissingPluginException {
      // Unsupported platform — ignore.
    } on PlatformException {
      // Native failure — ignore so UI still works.
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>('disable');
    } on MissingPluginException {
      // Unsupported platform — ignore.
    } on PlatformException {
      // Native failure — ignore.
    }
  }
}
