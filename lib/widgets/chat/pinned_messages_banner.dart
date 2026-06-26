// Widget: PinnedMessagesBanner — premium pinned messages strip
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/premium/premium_design_system.dart';

/// Banner showing pinned message count; tap to open pinned list.
class PinnedMessagesBanner extends ConsumerWidget {
  final int pinnedCount;
  final VoidCallback? onTap;

  const PinnedMessagesBanner({
    super.key,
    required this.pinnedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pinnedCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumPageHeader.horizontalPadding,
        AppSpacing.spacingSM,
        PremiumPageHeader.horizontalPadding,
        AppSpacing.spacingXS,
      ),
      child: PremiumTapScale(
        onTap: onTap ?? () {},
        semanticLabel: '$pinnedCount pinned messages',
        child: PremiumShell(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentViolet.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.getIconPath('bookmark'),
                    size: 16,
                    color: AppColors.accentViolet,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Text(
                  '$pinnedCount pinned message${pinnedCount > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSvgIcon(
                assetPath: AppIcons.arrowDown,
                size: 16,
                color: AppColors.accentViolet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
