// Screen: ProfileCompletionWelcomeScreen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../routes/app_router.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/avatar/animated_avatar.dart';

/// Profile completion welcome screen - Welcome users to profile completion
class ProfileCompletionWelcomeScreen extends StatefulWidget {
  const ProfileCompletionWelcomeScreen({super.key});

  @override
  State<ProfileCompletionWelcomeScreen> createState() =>
      _ProfileCompletionWelcomeScreenState();
}

class _ProfileCompletionWelcomeScreenState
    extends State<ProfileCompletionWelcomeScreen> {
  bool _ambientUnlocked = false;

  void _unlockAmbientIfAllowed() {
    if (_ambientUnlocked) return;
    if (!AppAnimations.animationsEnabled(context)) return;
    setState(() => _ambientUnlocked = true);
  }

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
    final ambientMotion = _ambientUnlocked &&
        AppAnimations.animationsEnabled(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Listener(
          onPointerDown: (_) => _unlockAmbientIfAllowed(),
          child: ResponsiveGrid.constrainedTo(
            context,
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacingXXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RepaintBoundary(
                    child: AnimatedAvatar(
                      key: const ValueKey('profile_completion_welcome_avatar'),
                      imageUrl: null,
                      name: 'You',
                      size: 120.0,
                      showPulse: ambientMotion,
                      animate: ambientMotion,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingXXL),
                  AppText(
                    'Complete Your Profile',
                    style: AppTypography.h1.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.spacingMD),
                  AppText(
                    'Add more details to your profile to get better matches and increase your chances of finding someone special!',
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.spacingXXL),
                  _WelcomeBenefitRow(
                    icon: AppIcons.favorite,
                    text: 'Get 3x more likes',
                  ),
                  const SizedBox(height: AppSpacing.spacingMD),
                  _WelcomeBenefitRow(
                    icon: AppIcons.visibility,
                    text: 'Appear in more searches',
                  ),
                  const SizedBox(height: AppSpacing.spacingMD),
                  const _WelcomeBenefitRow(
                    icon: AppIcons.star,
                    text: 'Better match quality',
                  ),
                  const SizedBox(height: AppSpacing.spacingXXL),
                  GradientButton(
                    text: 'Get Started',
                    onPressed: () {
                      context.push(AppRoutes.profileWizard);
                    },
                    isFullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.spacingMD),
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
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
      ),
    );
  }
}

class _WelcomeBenefitRow extends StatelessWidget {
  const _WelcomeBenefitRow({
    required this.icon,
    required this.text,
  });

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(
          assetPath: icon,
          size: 24,
          color: AppColors.accentPurple,
        ),
        const SizedBox(width: AppSpacing.spacingMD),
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
