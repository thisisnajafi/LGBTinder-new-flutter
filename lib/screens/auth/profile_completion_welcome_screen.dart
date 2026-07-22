// Screen: ProfileCompletionWelcomeScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/avatar/animated_avatar.dart';
import '../../core/utils/app_icons.dart';

/// Profile completion welcome screen - Welcome users to profile completion
class ProfileCompletionWelcomeScreen extends ConsumerStatefulWidget {
  const ProfileCompletionWelcomeScreen({super.key});

  @override
  ConsumerState<ProfileCompletionWelcomeScreen> createState() =>
      _ProfileCompletionWelcomeScreenState();
}

class _ProfileCompletionWelcomeScreenState
    extends ConsumerState<ProfileCompletionWelcomeScreen> {
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ResponsiveGrid.constrainedTo(
          context,
          Padding(
            padding: EdgeInsets.all(AppSpacing.spacingXXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedAvatar(
                  imageUrl: null,
                  name: 'You',
                  size: 120.0,
                  showPulse: true,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                AppText(
                  'Complete Your Profile',
                  style: AppTypography.h1.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                AppText(
                  'Add more details to your profile to get better matches and increase your chances of finding someone special!',
                  style: AppTypography.body.copyWith(
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                _buildBenefitItem(
                  icon: AppIcons.favorite,
                  text: 'Get 3x more likes',
                  textColor: textColor,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                _buildBenefitItem(
                  icon: AppIcons.visibility,
                  text: 'Appear in more searches',
                  textColor: textColor,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                _buildBenefitItem(
                  icon: AppIcons.star,
                  text: 'Better match quality',
                  textColor: textColor,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                GradientButton(
                  text: 'Get Started',
                  onPressed: () {
                    context.push('/profile-completion');
                  },
                  isFullWidth: true,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Text(
                    'Maybe Later',
                    style: AppTypography.button.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          tablet: 500,
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required String icon,
    required String text,
    required Color textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(
          assetPath: icon,
          size: 24,
          color: AppColors.accentPurple,
        ),
        SizedBox(width: AppSpacing.spacingMD),
        Flexible(
          child: AppText(
            text,
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
