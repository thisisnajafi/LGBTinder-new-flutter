// Widget: MentionTextWidget
// Text widget with mention highlighting
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';

/// Mention text widget
/// Displays text with highlighted @mentions
class MentionTextWidget extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final Function(int userId)? onMentionTap;

  const MentionTextWidget({
    Key? key,
    required this.text,
    this.style,
    this.onMentionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = style ?? AppTypography.body;
    final mentionStyle = defaultStyle.copyWith(
      color: AppColors.accentPurple,
      fontWeight: FontWeight.w600,
    );

    // Parse mentions (@username)
    final mentionPattern = RegExp(r'@(\w+)');
    final matches = mentionPattern.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before mention
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      // Add mention
      final mentionText = match.group(0)!;
      spans.add(TextSpan(
        text: mentionText,
        style: mentionStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            // TODO: Extract user ID from mention
            onMentionTap?.call(0);
          },
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
