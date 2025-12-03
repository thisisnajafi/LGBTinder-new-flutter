// Stats display card
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../theme/spacing_constants.dart';
import '../theme/border_radius_constants.dart';

/// Profile statistics card widget
/// Displays matches, likes, and views count
class ProfileStatsCard extends ConsumerWidget {
  final int matchesCount;
  final int likesCount;
  final int viewsCount;

  const ProfileStatsCard({
    Key? key,
    required this.matchesCount,
    required this.likesCount,
    required this.viewsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingMD,
      ),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Matches',
            matchesCount.toString(),
            Icons.favorite,
            AppColors.notificationRed,
            textColor,
            secondaryTextColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: borderColor,
          ),
          _buildStatItem(
            context,
            'Likes',
            likesCount.toString(),
            Icons.thumb_up,
            AppColors.onlineGreen,
            textColor,
            secondaryTextColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: borderColor,
          ),
          _buildStatItem(
            context,
            'Views',
            viewsCount.toString(),
            Icons.visibility,
            AppColors.accentPurple,
            textColor,
            secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          SizedBox(height: AppSpacing.spacingXS),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacingXS),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
