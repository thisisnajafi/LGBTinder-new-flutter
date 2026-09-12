import 'dart:async';

import 'package:flutter/services.dart';

import '../services/app_logger.dart';

/// Android FLAG_SECURE plus iOS screenshot notifications (CHAT-SD-005).
class ScreenshotProtection {
  ScreenshotProtection._();

  static const MethodChannel _channel =
      MethodChannel('com.lgbtfinder/screenshot_protection');

  static const String screenshotTakenMethod = 'screenshotTaken';

  static final StreamController<void> _screenshots =
      StreamController<void>.broadcast();

  static bool _handlerBound = false;

  /// Fires when the OS reports a screenshot (iOS; Android is usually blocked).
  static Stream<void> get screenshots {
    _bindHandler();
    return _screenshots.stream;
  }

  static void _bindHandler() {
    if (_handlerBound) return;
    _handlerBound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == screenshotTakenMethod) {
        AppLogger.warning(
          'OS screenshot notification',
          tag: 'Chat',
        );
        if (!_screenshots.isClosed) {
          _screenshots.add(null);
        }
      }
    });
  }

  static Future<void> enable() async {
    _bindHandler();
    try {
      await _channel.invokeMethod<void>('enable');
    } on MissingPluginException catch (e) {
      AppLogger.warning(
        'Screenshot protection plugin missing',
        tag: 'Chat',
        error: e,
      );
    } on PlatformException catch (e) {
      AppLogger.warning(
        'Screenshot protection enable failed',
        tag: 'Chat',
        error: e,
      );
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>('disable');
    } on MissingPluginException catch (e) {
      AppLogger.warning(
        'Screenshot protection plugin missing',
        tag: 'Chat',
        error: e,
      );
    } on PlatformException catch (e) {
      AppLogger.warning(
        'Screenshot protection disable failed',
        tag: 'Chat',
        error: e,
      );
    }
  }
}
