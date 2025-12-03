// Screen: SafetyCenterScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import 'blocked_users_screen.dart';
import 'report_history_screen.dart';
import 'emergency_contacts_screen.dart';

/// Safety center screen - Safety tools and resources
class SafetyCenterScreen extends ConsumerWidget {
  const SafetyCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Safety Center',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Safety header
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingXXL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.notificationRed.withOpacity(0.2),
                  AppColors.accentPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shield,
                  size: 64,
                  color: AppColors.accentPurple,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Your Safety Matters',
                  style: AppTypography.h1.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'We\'re here to help you stay safe while connecting',
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),

          // Quick actions
          SectionHeader(
            title: 'Quick Actions',
            icon: Icons.flash_on,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSafetyCard(
            context: context,
            icon: Icons.block,
            title: 'Blocked Users',
            description: 'View and manage blocked users',
            color: AppColors.notificationRed,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedUsersScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSafetyCard(
            context: context,
            icon: Icons.report,
            title: 'Report History',
            description: 'View your reports and their status',
            color: AppColors.warningYellow,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportHistoryScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSafetyCard(
            context: context,
            icon: Icons.emergency,
            title: 'Emergency Contacts',
            description: 'Add trusted contacts for emergencies',
            color: AppColors.onlineGreen,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyContactsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Safety tips
          SectionHeader(
            title: 'Safety Tips',
            icon: Icons.lightbulb_outline,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildTipCard(
            context: context,
            tip: 'Never share personal information like your address or financial details',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildTipCard(
            context: context,
            tip: 'Meet in public places for first dates and let someone know where you\'re going',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildTipCard(
            context: context,
            tip: 'Trust your instincts - if something feels off, it probably is',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
          ),
          SizedBox(height: AppSpacing.spacingXXL),

          // Report button
          GradientButton(
            text: 'Report a Problem',
            onPressed: () {
              // TODO: Open report dialog
            },
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(width: AppSpacing.spacingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    description,
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required BuildContext context,
    required String tip,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.onlineGreen,
            size: 20,
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Text(
              tip,
              style: AppTypography.body.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
