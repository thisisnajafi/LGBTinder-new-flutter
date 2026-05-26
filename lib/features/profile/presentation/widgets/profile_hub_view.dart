import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/profile_image_widget.dart';

/// Profile hub layout (REF-01) — avatar hero, stats row, grouped menu list.
class ProfileHubView extends StatelessWidget {
  final String fullName;
  final String? avatarUrl;
  final int? age;
  final String activityLabel;
  final String creditsLabel;
  final bool isVerified;
  final VoidCallback onViewProfile;
  final List<ProfileHubSection> sections;

  const ProfileHubView({
    super.key,
    required this.fullName,
    this.avatarUrl,
    this.age,
    required this.activityLabel,
    required this.creditsLabel,
    this.isVerified = false,
    required this.onViewProfile,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'Profile',
                action: TextButton(
                  onPressed: onViewProfile,
                  child: Text(
                    'View profile',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spacingXL),
              _ProfileHeroBlock(
                fullName: fullName,
                avatarUrl: avatarUrl,
                age: age,
                activityLabel: activityLabel,
                isVerified: isVerified,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPageHeader.horizontalPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ProfileStatCard(
                        iconPath: AppIcons.flash,
                        label: 'Activity',
                        value: activityLabel,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacingMD),
                    Expanded(
                      child: _ProfileStatCard(
                        iconPath: AppIcons.coin,
                        label: 'Credits',
                        value: creditsLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spacingXL),
              for (final section in sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppPageHeader.horizontalPadding,
                    AppSpacing.spacingXL,
                    AppPageHeader.horizontalPadding,
                    AppSpacing.spacingSM,
                  ),
                  child: Text(
                    section.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                for (var i = 0; i < section.items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPageHeader.horizontalPadding,
                    ),
                    child: _ProfileMenuItem(
                      iconPath: section.items[i].iconPath,
                      label: section.items[i].label,
                      onTap: section.items[i].onTap,
                      showDivider: i < section.items.length - 1,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.spacingXXL),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileHubSection {
  final String title;
  final List<ProfileHubMenuItem> items;

  const ProfileHubSection({
    required this.title,
    required this.items,
  });
}

class ProfileHubMenuItem {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const ProfileHubMenuItem({
    required this.iconPath,
    required this.label,
    required this.onTap,
  });
}

class _ProfileHeroBlock extends StatelessWidget {
  final String fullName;
  final String? avatarUrl;
  final int? age;
  final String activityLabel;
  final bool isVerified;

  const _ProfileHeroBlock({
    required this.fullName,
    this.avatarUrl,
    this.age,
    required this.activityLabel,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2.5,
                ),
              ),
              child: ClipOval(
                child: ProfileImageWidget(
                  imageUrl: avatarUrl,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (age != null)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingSM,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  ),
                  child: Text(
                    '$age',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacingMD),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fullName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: AppSpacing.spacingXS),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: AppSvgIcon(
                  assetPath: AppIcons.check,
                  size: 11,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.spacingXS),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.flash,
              size: 14,
              color: mutedColor,
            ),
            const SizedBox(width: AppSpacing.spacingXS),
            Text(
              'Your activity · $activityLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String iconPath;
  final String label;
  final String value;

  const _ProfileStatCard({
    required this.iconPath,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceElevatedLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingMD,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            assetPath: iconPath,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _ProfileMenuItem({
    required this.iconPath,
    required this.label,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.radiusXS),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.radiusXS),
                      ),
                      child: Center(
                        child: AppSvgIcon(
                          assetPath: iconPath,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    AppSvgIcon(
                      assetPath: AppIcons.chevronRight,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 0.5, thickness: 0.5, color: dividerColor),
      ],
    );
  }
}
