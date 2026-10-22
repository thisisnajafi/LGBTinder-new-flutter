import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the full-screen incoming-call prompt should open.
bool shouldPromptFullScreenIntent({
  required bool canUseFullScreenIntent,
  required bool alreadyPrompted,
}) {
  if (canUseFullScreenIntent) return false;
  return !alreadyPrompted;
}

/// Button the user picked on the one-time incoming-call dialog.
enum FullScreenIntentChoice { notNow, openSettings }

/// Remembers that the signed-in user was already asked.
class FullScreenIntentPromptSession {
  FullScreenIntentPromptSession({this.alreadyPrompted = false});

  bool alreadyPrompted;

  bool shouldAsk({required bool canUseFullScreenIntent}) {
    return shouldPromptFullScreenIntent(
      canUseFullScreenIntent: canUseFullScreenIntent,
      alreadyPrompted: alreadyPrompted,
    );
  }

  /// Both "Not now" and "Open settings" count as the one ask.
  void remember(FullScreenIntentChoice choice) {
    switch (choice) {
      case FullScreenIntentChoice.notNow:
      case FullScreenIntentChoice.openSettings:
        alreadyPrompted = true;
    }
  }
}

/// Android 14+ full-screen intent is not granted with the manifest permission.
/// Ask once after login, when the home shell is visible.
class FullScreenIntentGate {
  FullScreenIntentGate._();

  static const promptedKey = 'full_screen_intent_prompted_v1';
  static const MethodChannel channel = MethodChannel(
    'com.lgbtfinder/full_screen_intent',
  );

  static Future<void> promptOnceAfterLogin(BuildContext context) async {
    if (!Platform.isAndroid) {
      debugPrint('[FSIGate] skip non-android');
      return;
    }

    final bool canUse;
    try {
      final allowed = await channel.invokeMethod<bool>('canUseFullScreenIntent');
      canUse = allowed == true;
      debugPrint('[FSIGate] canUseFullScreenIntent=$canUse');
    } catch (e) {
      debugPrint('[FSIGate] canUseFullScreenIntent failed: $e');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool(promptedKey) ?? false;
    debugPrint('[FSIGate] alreadyPrompted=$already');
    final session = FullScreenIntentPromptSession(alreadyPrompted: already);
    if (!session.shouldAsk(canUseFullScreenIntent: canUse)) {
      debugPrint('[FSIGate] skip');
      return;
    }
    if (!context.mounted) return;

    final choice = await showDialog<FullScreenIntentChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text(
            'Incoming calls',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            'Allow full-screen incoming calls so a call can ring when your phone is locked.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                FullScreenIntentChoice.notNow,
              ),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                FullScreenIntentChoice.openSettings,
              ),
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
    if (choice == null) {
      debugPrint('[FSIGate] dismissed');
      return;
    }

    session.remember(choice);
    await prefs.setBool(promptedKey, true);
    if (choice == FullScreenIntentChoice.openSettings) {
      debugPrint('[FSIGate] open settings');
      try {
        await channel.invokeMethod<void>('openFullScreenIntentSettings');
      } catch (e) {
        debugPrint('[FSIGate] open settings failed: $e');
      }
      return;
    }
    debugPrint('[FSIGate] not now');
  }
}
