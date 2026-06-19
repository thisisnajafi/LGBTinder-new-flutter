import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../core/widgets/profile_age_badge.dart';
import '../../../../core/widgets/profile_image_widget.dart';

/// Profile hub layout (REF-01) — avatar hero and grouped menu list.
class ProfileHubView extends StatelessWidget {
  final String fullName;
  final String? avatarUrl;
  final int? age;
  final bool isVerified;
  final VoidCallback onViewProfile;
  final List<ProfileHubSection> sections;

  const ProfileHubView({
    super.key,
    required this.fullName,
    this.avatarUrl,
    this.age,
    this.isVerified = false,
    required this.onViewProfile,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumPageHeader(
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
                isVerified: isVerified,
              ),
              for (var i = 0; i < sections.length; i++) ...[
                const SizedBox(height: AppSpacing.spacingXL),
                PremiumSettingsGroup(
                  title: sections[i].title,
                  children: [
                    for (final item in sections[i].items)
                      PremiumSettingsTile(
                        iconPath: item.iconPath,
                        title: item.label,
                        onTap: item.onTap,
                      ),
                  ],
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
  final bool isVerified;

  const _ProfileHeroBlock({
    required this.fullName,
    this.avatarUrl,
    this.age,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const avatarSize = 88.0;
    const ageBadgeHalfHeight = 10.0;

    return Column(
      children: [
        SizedBox(
          width: avatarSize,
          height: avatarSize + ageBadgeHalfHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface,
                  ),
                  child: ClipOval(
                    child: ProfileImageWidget(
                      imageUrl: avatarUrl,
                      width: avatarSize - 5,
                      height: avatarSize - 5,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              if (age != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: avatarSize - ageBadgeHalfHeight - 1,
                  child: Center(
                    child: ProfileAgeBadge(
                      age: age!,
                      style: ProfileAgeBadgeStyle.avatarOverlay,
                    ),
                  ),
                ),
            ],
          ),
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
      ],
    );
  }
}
