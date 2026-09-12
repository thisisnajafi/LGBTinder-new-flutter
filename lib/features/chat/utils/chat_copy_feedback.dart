import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/animation_constants.dart';

/// Clipboard + 2s “Copied” snackbar (CHAT-FEAT-002).
class ChatCopyFeedback {
  ChatCopyFeedback._();

  static const String label = 'Copied';

  static Future<void> copy(String text) {
    return Clipboard.setData(ClipboardData(text: text.trim()));
  }

  static SnackBar snackBar(BuildContext context) {
    return SnackBar(
      duration: AppAnimations.chatCopySnackbarHold,
      content: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
