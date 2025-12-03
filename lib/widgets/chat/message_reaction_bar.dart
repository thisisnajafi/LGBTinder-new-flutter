// Widget: MessageReactionBar
// Message reaction emoji bar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Message reaction bar widget
/// Displays emoji reactions on messages
class MessageReactionBar extends ConsumerWidget {
  final Map<String, int> reactions; // emoji -> count
  final Function(String emoji)? onReactionTap;
  final bool isSent;

  const MessageReactionBar({
    Key? key,
    this.reactions = const {},
    this.onReactionTap,
    this.isSent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Wrap(
      spacing: AppSpacing.spacingXS,
      runSpacing: AppSpacing.spacingXS,
      children: reactions.entries.map((entry) {
        return GestureDetector(
          onTap: () => onReactionTap?.call(entry.key),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingSM,
              vertical: AppSpacing.spacingXS,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(fontSize: 14),
                ),
                if (entry.value > 1) ...[
                  SizedBox(width: AppSpacing.spacingXS),
                  Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
