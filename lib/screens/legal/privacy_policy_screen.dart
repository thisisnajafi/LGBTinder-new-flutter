// Screen: PrivacyPolicyScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';

/// Privacy policy screen - Display privacy policy
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

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
        title: 'Privacy Policy',
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
              title: '1. Information We Collect',
              content:
                  'We collect information you provide directly to us, such as when you create an account, complete your profile, use our services, or contact us for support.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '2. How We Use Your Information',
              content:
                  'We use the information we collect to provide, maintain, and improve our services, process transactions, send you communications, and protect our users.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '3. Information Sharing',
              content:
                  'We do not sell your personal information. We may share your information only in limited circumstances, such as with your consent, to comply with legal obligations, or to protect our users.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '4. Data Security',
              content:
                  'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '5. Your Rights',
              content:
                  'You have the right to access, update, or delete your personal information. You can also opt out of certain communications and data processing activities.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _buildSection(
              title: '6. Contact Us',
              content:
                  'If you have questions about this Privacy Policy, please contact us at privacy@lgbtfinder.com.',
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
