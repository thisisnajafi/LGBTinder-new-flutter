import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/utils/app_icons.dart';
import 'profile_info_pill.dart';

/// Interest chips with optional shared-interest highlighting.
class InterestChipList extends ConsumerWidget {
  final List<String> interests;
  final Set<String>? sharedInterests;
  final bool isEditable;
  final VoidCallback? onEdit;
  final int? maxChipsToShow;

  const InterestChipList({
    super.key,
    required this.interests,
    this.sharedInterests,
    this.isEditable = false,
    this.onEdit,
    this.maxChipsToShow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final display = maxChipsToShow != null && interests.length > maxChipsToShow!
        ? interests.sublist(0, maxChipsToShow!)
        : interests;
    final hasMore = maxChipsToShow != null && interests.length > maxChipsToShow!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Interests',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (isEditable && onEdit != null) ...[
                const Spacer(),
                Semantics(
                  label: 'Edit interests',
                  button: true,
                  child: IconButton(
                    onPressed: onEdit,
                    icon: AppSvgIcon(
                      assetPath: AppIcons.edit,
                      size: 20,
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          if (interests.isEmpty)
            Text(
              isEditable
                  ? 'Add your interests to help others know you better'
                  : 'No interests added yet',
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: [
                ...display.map((interest) {
                  final shared = sharedInterests?.contains(interest) ?? false;
                  return shared
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingMD,
                            vertical: AppSpacing.spacingSM,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                          ),
                          child: Text(
                            interest,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : ProfileInfoPill(
                          iconPath: AppIcons.getIconPath('tag'),
                          label: interest,
                        );
                }),
                if (hasMore)
                  ProfileInfoPill(
                    iconPath: AppIcons.getIconPath('tag'),
                    label: '+${interests.length - maxChipsToShow!} more',
                    highlighted: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
