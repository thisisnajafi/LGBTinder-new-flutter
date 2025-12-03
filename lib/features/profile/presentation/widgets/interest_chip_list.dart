import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

/// Interest chip list widget
/// Displays a list of user interests as chips
class InterestChipList extends ConsumerWidget {
  final List<String> interests;
  final bool isEditable;
  final VoidCallback? onEdit;
  final int? maxChipsToShow;

  const InterestChipList({
    Key? key,
    required this.interests,
    this.isEditable = false,
    this.onEdit,
    this.maxChipsToShow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayInterests = maxChipsToShow != null && interests.length > maxChipsToShow!
        ? interests.sublist(0, maxChipsToShow!)
        : interests;

    final hasMore = maxChipsToShow != null && interests.length > maxChipsToShow!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Interests',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (isEditable && onEdit != null) ...[
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Edit interests',
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (interests.isEmpty)
            Text(
              isEditable
                  ? 'Add your interests to help others know you better'
                  : 'No interests added yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...displayInterests.map((interest) => _buildInterestChip(
                  context,
                  interest,
                  _getInterestColor(interest),
                )),
                if (hasMore)
                  Chip(
                    label: Text(
                      '+${interests.length - maxChipsToShow!} more',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInterestChip(BuildContext context, String interest, Color color) {
    final theme = Theme.of(context);

    return Chip(
      label: Text(
        interest,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(
        color: color.withOpacity(0.3),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getInterestColor(String interest) {
    // Generate consistent colors based on interest name
    final colors = [
      AppColors.primaryLight,
      AppColors.secondaryLight,
      AppColors.feedbackSuccess,
      AppColors.feedbackWarning,
      AppColors.feedbackError,
      AppColors.feedbackInfo,
      AppColors.accentPurple,
      AppColors.accentPink,
    ];

    final hash = interest.hashCode.abs();
    return colors[hash % colors.length];
  }
}
