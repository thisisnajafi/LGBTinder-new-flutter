// Screen: ProfileCompletionIncentivesScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/buttons/gradient_button.dart';

/// Profile completion incentives screen - Incentives for completing profile
class ProfileCompletionIncentivesScreen extends ConsumerStatefulWidget {
  const ProfileCompletionIncentivesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileCompletionIncentivesScreen> createState() => _ProfileCompletionIncentivesScreenState();
}

class _ProfileCompletionIncentivesScreenState extends ConsumerState<ProfileCompletionIncentivesScreen> {
  int _profileCompletion = 65;
  List<Map<String, dynamic>> _incentives = [];

  @override
  void initState() {
    super.initState();
    _loadIncentives();
  }

  Future<void> _loadIncentives() async {
    // TODO: Load incentives from API
    setState(() {
      _incentives = [
        {
          'id': '1',
          'title': 'Add Profile Photo',
          'description': 'Upload at least one photo',
          'points': 20,
          'is_completed': true,
          'icon': Icons.camera_alt,
        },
        {
          'id': '2',
          'title': 'Complete Bio',
          'description': 'Write a bio about yourself',
          'points': 15,
          'is_completed': true,
          'icon': Icons.description,
        },
        {
          'id': '3',
          'title': 'Add Interests',
          'description': 'Select at least 3 interests',
          'points': 10,
          'is_completed': false,
          'icon': Icons.favorite,
        },
        {
          'id': '4',
          'title': 'Verify Account',
          'description': 'Complete account verification',
          'points': 30,
          'is_completed': false,
          'icon': Icons.verified,
        },
        {
          'id': '5',
          'title': 'Add Location',
          'description': 'Set your city and country',
          'points': 10,
          'is_completed': true,
          'icon': Icons.location_on,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Complete Your Profile',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentPurple,
                  AppColors.accentPurple.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Column(
              children: [
                Text(
                  'Profile Completion',
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _profileCompletion / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Text(
                      '$_profileCompletion%',
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
                  style: AppTypography.body.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          SectionHeader(
            title: 'Earn Points & Rewards',
            icon: Icons.stars,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Complete these tasks to boost your profile and earn rewards',
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
          SizedBox(height: AppSpacing.spacingLG),
          ..._incentives.map((incentive) {
            return _buildIncentiveCard(
              incentive: incentive,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            );
          }),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Benefits
          SectionHeader(
            title: 'Benefits of Completing',
            icon: Icons.thumb_up,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildBenefitItem(
            icon: Icons.trending_up,
            title: '3x More Matches',
            description: 'Complete profiles get more visibility',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildBenefitItem(
            icon: Icons.verified,
            title: 'Verified Badge',
            description: 'Show others you\'re authentic',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildBenefitItem(
            icon: Icons.star,
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

  Widget _buildIncentiveCard({
    required Map<String, dynamic> incentive,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final isCompleted = incentive['is_completed'] ?? false;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isCompleted
              ? AppColors.onlineGreen
              : borderColor,
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
                  ? AppColors.onlineGreen.withOpacity(0.2)
                  : AppColors.accentPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Icon(
              incentive['icon'],
              color: isCompleted
                  ? AppColors.onlineGreen
                  : AppColors.accentPurple,
              size: 28,
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
                        incentive['title'],
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
                        color: AppColors.warningYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      child: Text(
                        '+${incentive['points']} pts',
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
                  incentive['description'],
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Icon(
              Icons.check_circle,
              color: AppColors.onlineGreen,
              size: 24,
            )
          else
            IconButton(
              icon: Icon(
                Icons.arrow_forward,
                color: AppColors.accentPurple,
              ),
              onPressed: () {
                // TODO: Navigate to relevant screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Complete: ${incentive['title']}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
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
              color: AppColors.accentPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            ),
            child: Icon(
              icon,
              color: AppColors.accentPurple,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
