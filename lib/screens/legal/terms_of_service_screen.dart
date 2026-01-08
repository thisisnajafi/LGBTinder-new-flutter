// Screen: TermsOfServiceScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';

/// Terms of service screen - Display terms of service
class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Terms of Service',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: December 2024',
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
            SizedBox(height: AppSpacing.spacingXXL),
            _buildSection(
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using LGBTFinder, you accept and agree to be bound by the terms and provision of this agreement.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '2. User Accounts',
              content:
                  'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '3. User Conduct',
              content:
                  'You agree not to use the service to: harass, abuse, or harm other users; post false or misleading information; violate any applicable laws or regulations.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '4. Privacy',
              content:
                  'Your use of LGBTFinder is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '5. Premium Features',
              content:
                  'Premium features are available through subscription. Subscriptions will automatically renew unless cancelled. You can cancel your subscription at any time.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '6. Termination',
              content:
                  'We reserve the right to terminate or suspend your account and access to the service immediately, without prior notice, for conduct that we believe violates these Terms of Service.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '7. Contact Information',
              content:
                  'If you have any questions about these Terms of Service, please contact us at legal@lgbtfinder.com.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h2.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacingMD),
        Text(
          content,
          style: AppTypography.body.copyWith(
            color: secondaryTextColor,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
