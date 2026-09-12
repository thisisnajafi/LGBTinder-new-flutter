import 'package:flutter/material.dart';

/// Case-insensitive substring spans for messenger search (CHAT-MSG-003).
class ChatSearchHighlight {
  ChatSearchHighlight._();

  static List<InlineSpan> spans({
    required String text,
    required String query,
    required TextStyle style,
    required Color highlightColor,
  }) {
    final needle = query.trim();
    if (needle.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final matches =
        RegExp(RegExp.escape(needle), caseSensitive: false).allMatches(text);
    if (matches.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final highlight = style.copyWith(color: highlightColor);
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: style));
      }
      spans.add(TextSpan(text: match.group(0), style: highlight));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
    return spans;
  }
}
