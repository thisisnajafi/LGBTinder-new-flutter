// Widget: SafetyVerificationSection
// Safety verification section
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../badges/verification_badge.dart';

/// Safety verification section widget
/// Displays safety and verification status
class SafetyVerificationSection extends ConsumerWidget {
  final bool isVerified;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final VoidCallback? onVerifyTap;

  const SafetyVerificationSection({
    Key? key,
    this.isVerified = false,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.onVerifyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: AppColors.accentPurple,
                size: 24,
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Text(
                'Safety & Verification',
                style: AppTypography.h3.copyWith(color: textColor),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingLG),
          _buildVerificationItem(
            context: context,
            label: 'Profile Verification',
            isVerified: isVerified,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildVerificationItem(
            context: context,
            label: 'Email Verification',
            isVerified: isEmailVerified,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildVerificationItem(
            context: context,
            label: 'Phone Verification',
            isVerified: isPhoneVerified,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          if (!isVerified && onVerifyTap != null) ...[
            SizedBox(height: AppSpacing.spacingLG),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVerifyTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                ),
                child: Text(
                  'Verify Profile',
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationItem({
    required BuildContext context,
    required String label,
    required bool isVerified,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle : Icons.circle_outlined,
          color: isVerified ? AppColors.onlineGreen : secondaryTextColor,
          size: 20,
        ),
        SizedBox(width: AppSpacing.spacingMD),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(color: textColor),
          ),
        ),
        if (isVerified)
          VerificationBadge(isVerified: true, size: 20),
      ],
    );
  }
}
