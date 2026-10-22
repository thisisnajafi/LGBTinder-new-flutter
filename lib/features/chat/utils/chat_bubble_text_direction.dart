import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

/// Reading direction of a single message, from its first strong character.
///
/// Bubble side stays with the sender. Only the text inside follows this.
class ChatBubbleTextDirection {
  ChatBubbleTextDirection._();

  static TextDirection of(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return TextDirection.ltr;
    return intl.Bidi.detectRtlDirectionality(trimmed)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}
