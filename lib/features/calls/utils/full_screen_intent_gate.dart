import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/app_logger.dart';

/// Whether the full-screen incoming-call prompt should open.
bool shouldPromptFullScreenIntent({
  required bool canUseFullScreenIntent,
  required bool alreadyPrompted,
}) {
  if (canUseFullScreenIntent) return false;
  return !alreadyPrompted;
}

/// Android 14+ full-screen intent is not granted with the manifest permission.
/// Ask once after login, and request POST_NOTIFICATIONS in the same step.
class FullScreenIntentGate {
  FullScreenIntentGate._();

  static const promptedKey = 'full_screen_intent_prompted_v1';

  static Future<void> promptOnceAfterLogin() async {
    try {
      await FlutterCallkitIncoming.requestNotificationPermission(<String, dynamic>{
        'title': 'Calls and messages',
        'rationaleMessagePermission':
            'Allow notifications so incoming calls can ring.',
        'postNotificationMessageRequired':
            'Notifications are required for calls and messages.',
      });
    } catch (e) {
      AppLogger.warning(
        'POST_NOTIFICATIONS request failed',
        tag: 'CallKit',
        error: e,
      );
    }

    try {
      final allowed = await FlutterCallkitIncoming.canUseFullScreenIntent();
      final canUse = allowed == true;
      final prefs = await SharedPreferences.getInstance();
      final already = prefs.getBool(promptedKey) ?? false;
      if (!shouldPromptFullScreenIntent(
        canUseFullScreenIntent: canUse,
        alreadyPrompted: already,
      )) {
        return;
      }
      await prefs.setBool(promptedKey, true);
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (e) {
      AppLogger.warning(
        'Full-screen intent prompt failed',
        tag: 'CallKit',
        error: e,
      );
    }
  }
}
