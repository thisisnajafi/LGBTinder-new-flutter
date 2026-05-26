import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';

enum OnboardingProgressStyle { dots, segmentedBar }

/// Reusable onboarding progress — dots (intro) or segmented bar (wizard).
class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final OnboardingProgressStyle style;
  final bool lightOnDark;
  final String? stepLabel;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.style = OnboardingProgressStyle.segmentedBar,
    this.lightOnDark = false,
    this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = stepLabel ?? 'Step ${currentStep + 1} of $totalSteps';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (style == OnboardingProgressStyle.segmentedBar)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: lightOnDark
                    ? AppColors.textPrimaryDark.withValues(alpha: 0.85)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        style == OnboardingProgressStyle.dots
            ? _DotsRow(
                currentStep: currentStep,
                totalSteps: totalSteps,
                lightOnDark: lightOnDark,
              )
            : _SegmentedBar(
                currentStep: currentStep,
                totalSteps: totalSteps,
                lightOnDark: lightOnDark,
              ),
      ],
    );
  }
}

class _DotsRow extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool lightOnDark;

  const _DotsRow({
    required this.currentStep,
    required this.totalSteps,
    required this.lightOnDark,
  });

  @override
  Widget build(BuildContext context) {
    final active = lightOnDark ? AppColors.textPrimaryDark : AppColors.accentPurple;
    final inactive = lightOnDark
        ? AppColors.textPrimaryDark.withValues(alpha: 0.4)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        return AnimatedContainer(
          duration: AppAnimations.feedbackShort,
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingXS),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(AppRadius.radiusXS),
          ),
        );
      }),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool lightOnDark;

  const _SegmentedBar({
    required this.currentStep,
    required this.totalSteps,
    required this.lightOnDark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = lightOnDark
        ? AppColors.textPrimaryDark.withValues(alpha: 0.25)
        : (isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight);

    return Row(
      children: List.generate(totalSteps, (index) {
        final isComplete = index < currentStep;
        final isActive = index == currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 6,
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingXS / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              gradient: (isComplete || isActive)
                  ? AppColors.brandGradient
                  : null,
              color: (isComplete || isActive) ? null : inactive,
            ),
          ),
        );
      }),
    );
  }
}
