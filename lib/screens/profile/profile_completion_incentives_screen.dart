// Screen: ProfileCompletionIncentivesScreen
import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/common/section_header.dart';

class ProfileIncentive {
  const ProfileIncentive({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.isCompleted,
    required this.iconPath,
  });

  final String id;
  final String title;
  final String description;
  final int points;
  final bool isCompleted;
  final String iconPath;
}

class ProfileIncentiveCatalog {
  ProfileIncentiveCatalog._();

  static const int completionPercent = 65;

  static const List<ProfileIncentive> items = [
    ProfileIncentive(
      id: '1',
      title: 'Add Profile Photo',
      description: 'Upload at least one photo',
      points: 20,
      isCompleted: true,
      iconPath: AppIcons.image,
    ),
    ProfileIncentive(
      id: '2',
      title: 'Complete Bio',
      description: 'Write a bio about yourself',
      points: 15,
      isCompleted: true,
      iconPath: AppIcons.documentText,
    ),
    ProfileIncentive(
      id: '3',
      title: 'Add Interests',
      description: 'Select at least 3 interests',
      points: 10,
      isCompleted: false,
      iconPath: AppIcons.heart,
    ),
    ProfileIncentive(
      id: '4',
      title: 'Verify Account',
      description: 'Complete account verification',
      points: 30,
      isCompleted: false,
      iconPath: AppIcons.verify,
    ),
    ProfileIncentive(
      id: '5',
      title: 'Add Location',
      description: 'Set your city and country',
      points: 10,
      isCompleted: true,
      iconPath: AppIcons.location,
    ),
  ];
}

/// Profile completion incentives — static catalog (PERF-SCR-INCENT-001).
class ProfileCompletionIncentivesScreen extends StatelessWidget {
  const ProfileCompletionIncentivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return AppPageScaffold(
      title: 'Complete Your Profile',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          const _CompletionHero(
            percent: ProfileIncentiveCatalog.completionPercent,
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'Earn Points & Rewards',
            iconPath: AppIcons.star,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Complete these tasks to boost your profile and earn rewards',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
          ),
          SizedBox(height: AppSpacing.spacingLG),
          for (final incentive in ProfileIncentiveCatalog.items)
            _IncentiveCard(
              incentive: incentive,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'Benefits of Completing',
            iconPath: AppIcons.like,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _BenefitItem(
            iconPath: AppIcons.arrowUp,
            title: '3x More Matches',
            description: 'Complete profiles get more visibility',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _BenefitItem(
            iconPath: AppIcons.verify,
            title: 'Verified Badge',
            description: 'Show others you\'re authentic',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _BenefitItem(
            iconPath: AppIcons.star,
            title: 'Premium Features',
            description: 'Unlock premium features for free',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }
}

class _CompletionHero extends StatelessWidget {
  const _CompletionHero({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple,
            AppColors.accentPurple.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Column(
        children: [
          Text(
            'Profile Completion',
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '$percent%',
                style: AppTypography.h1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Complete your profile to get more matches!',
            style: AppTypography.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IncentiveCard extends StatelessWidget {
  const _IncentiveCard({
    required this.incentive,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final ProfileIncentive incentive;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final isCompleted = incentive.isCompleted;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isCompleted ? AppColors.onlineGreen : borderColor,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.onlineGreen.withValues(alpha: 0.2)
                  : AppColors.accentPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: incentive.iconPath,
                size: 28,
                color: isCompleted
                    ? AppColors.onlineGreen
                    : AppColors.accentPurple,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        incentive.title,
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingSM,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      child: Text(
                        '+${incentive.points} pts',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warningYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  incentive.description,
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            AppSvgIcon(
              assetPath: AppIcons.checkCircle,
              size: 24,
              color: AppColors.onlineGreen,
            )
          else
            IconButton(
              icon: AppSvgIcon(
                assetPath: AppIcons.arrowRight,
                size: 22,
                color: AppColors.accentPurple,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Complete: ${incentive.title}')),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.iconPath,
    required this.title,
    required this.description,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final String iconPath;
  final String title;
  final String description;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: iconPath,
                size: 20,
                color: AppColors.accentPurple,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: AppSpacing.spacingXS),
                AppText(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
