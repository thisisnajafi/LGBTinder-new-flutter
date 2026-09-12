import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../features/chat/utils/chat_search_highlight.dart';

/// One-line text with the search needle painted in [ColorScheme.primary].
class ChatSearchHighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;

  const ChatSearchHighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = style ?? theme.textTheme.bodyMedium;
    if (query.trim().isEmpty) {
      return AppText(
        text,
        maxLines: maxLines,
        style: resolved,
      );
    }

    return Text.rich(
      TextSpan(
        children: ChatSearchHighlight.spans(
          text: text,
          query: query,
          style: resolved ?? const TextStyle(),
          highlightColor: theme.colorScheme.primary,
        ),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
