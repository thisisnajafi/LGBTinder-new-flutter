import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';

enum OnboardingProgressStyle { dots, segmentedBar }

/// Reusable onboarding progress — dots (intro) or animated wizard bar.
class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final OnboardingProgressStyle style;
  final bool lightOnDark;
  final String? stepLabel;
  final List<String>? stepTitles;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.style = OnboardingProgressStyle.segmentedBar,
    this.lightOnDark = false,
    this.stepLabel,
    this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = stepLabel ?? 'Step ${currentStep + 1} of $totalSteps';
    final stepTitle = stepTitles != null &&
            currentStep >= 0 &&
            currentStep < stepTitles!.length
        ? stepTitles![currentStep]
        : null;

    if (style == OnboardingProgressStyle.dots) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DotsRow(
            currentStep: currentStep,
            totalSteps: totalSteps,
            lightOnDark: lightOnDark,
          ),
        ],
      );
    }

    return _EnhancedWizardProgress(
      currentStep: currentStep,
      totalSteps: totalSteps,
      lightOnDark: lightOnDark,
      stepLabel: label,
      stepTitle: stepTitle,
      textTheme: textTheme,
    );
  }
}

class _EnhancedWizardProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool lightOnDark;
  final String stepLabel;
  final String? stepTitle;
  final TextTheme textTheme;

  const _EnhancedWizardProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.lightOnDark,
    required this.stepLabel,
    required this.stepTitle,
    required this.textTheme,
  });

  Duration _duration(BuildContext context) {
    return AppAnimations.animationsEnabled(context)
        ? AppAnimations.transitionPage
        : Duration.zero;
  }

  Widget _stepTransition({
    required Widget child,
    required BuildContext context,
  }) {
    final duration = _duration(context);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppAnimations.curveDefault,
      switchOutCurve: AppAnimations.curveDefault,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppAnimations.curveDefault,
        ));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final duration = _duration(context);
    final progress = (currentStep + 1) / totalSteps;
    final percent = (progress * 100).round();

    final labelColor = lightOnDark
        ? AppColors.textPrimaryDark.withValues(alpha: 0.85)
        : theme.colorScheme.onSurface.withValues(alpha: 0.72);
    final titleColor = lightOnDark
        ? AppColors.textSecondaryDark
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final trackInactive = lightOnDark
        ? AppColors.textPrimaryDark.withValues(alpha: 0.18)
        : (isDark
            ? AppColors.borderMediumDark.withValues(alpha: 0.65)
            : AppColors.borderMediumLight);
    final shellColor = lightOnDark
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.45 : 0.65,
          );
    final shellBorder = lightOnDark
        ? Colors.white.withValues(alpha: 0.12)
        : theme.colorScheme.outline.withValues(alpha: 0.14);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacingMD,
        AppSpacing.spacingMD,
        AppSpacing.spacingMD,
        AppSpacing.spacingSM + 2,
      ),
      decoration: BoxDecoration(
        color: shellColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: shellBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: duration,
                curve: AppAnimations.curveDefault,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _stepTransition(
                  context: context,
                  child: Text(
                    '${currentStep + 1}',
                    key: ValueKey<int>(currentStep),
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stepTransition(
                      context: context,
                      child: Text(
                        stepLabel,
                        key: ValueKey<String>('label-$currentStep'),
                        style: textTheme.labelLarge?.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (stepTitle != null) ...[
                      const SizedBox(height: 2),
                      _stepTransition(
                        context: context,
                        child: Text(
                          stepTitle!,
                          key: ValueKey<String>('title-$currentStep'),
                          style: textTheme.bodySmall?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              _stepTransition(
                context: context,
                child: Text(
                  '$percent%',
                  key: ValueKey<int>(percent),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    foreground: Paint()
                      ..shader = AppColors.brandGradient.createShader(
                        const Rect.fromLTWH(0, 0, 48, 24),
                      ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          LayoutBuilder(
            builder: (context, constraints) {
              const thumbSize = 10.0;
              final trackWidth = constraints.maxWidth;

              double stepCenter(int index) =>
                  (index + 0.5) / totalSteps * trackWidth;

              final thumbCenter = stepCenter(currentStep);
              final fillWidth = thumbCenter.clamp(0.0, trackWidth);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: trackInactive),
                          AnimatedContainer(
                            duration: duration,
                            curve: AppAnimations.curveEmphasized,
                            width: fillWidth,
                            decoration: const BoxDecoration(
                              gradient: AppColors.brandGradient,
                            ),
                          ),
                          if (AppAnimations.animationsEnabled(context))
                            AnimatedPositioned(
                              duration: duration,
                              curve: AppAnimations.curveEmphasized,
                              left: (thumbCenter - thumbSize / 2)
                                  .clamp(0.0, trackWidth - thumbSize),
                              top: -1,
                              child: Container(
                                width: thumbSize,
                                height: thumbSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentPurple
                                          .withValues(alpha: 0.45),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingSM),
                  SizedBox(
                    height: 12,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: List.generate(totalSteps, (index) {
                        final isComplete = index < currentStep;
                        final isActive = index == currentStep;
                        final isFilled = isComplete || isActive;
                        final dotSize = isActive ? 8.0 : 6.0;
                        final center = stepCenter(index);

                        return AnimatedPositioned(
                          duration: duration,
                          curve: AppAnimations.curveDefault,
                          left: center - dotSize / 2,
                          top: (12 - dotSize) / 2,
                          child: AnimatedContainer(
                            duration: duration,
                            curve: AppAnimations.curveDefault,
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  isFilled ? AppColors.brandGradient : null,
                              color: isFilled ? null : trackInactive,
                              border: isActive
                                  ? Border.all(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      width: 1.25,
                                    )
                                  : null,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accentPurple
                                            .withValues(alpha: 0.35),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingXS),
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
