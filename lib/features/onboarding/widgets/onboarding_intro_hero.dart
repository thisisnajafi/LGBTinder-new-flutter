import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';

/// SVG hero illustration for intro onboarding slides.
class OnboardingIntroHero extends StatefulWidget {
  final String iconPath;
  final bool animate;

  const OnboardingIntroHero({
    super.key,
    required this.iconPath,
    this.animate = true,
  });

  @override
  State<OnboardingIntroHero> createState() => _OnboardingIntroHeroState();
}

class _OnboardingIntroHeroState extends State<OnboardingIntroHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.animate && AppAnimations.animationsEnabled(context)) {
        _controller.forward();
      } else {
        _controller.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Onboarding illustration',
      child: ScaleTransition(
        scale: _scale,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textPrimaryDark.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.textPrimaryDark.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: AppSvgIcon(
                  assetPath: widget.iconPath,
                  size: 96,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Typing dots for chat intro slide.
class OnboardingTypingDots extends StatefulWidget {
  const OnboardingTypingDots({super.key});

  @override
  State<OnboardingTypingDots> createState() => _OnboardingTypingDotsState();
}

class _OnboardingTypingDotsState extends State<OnboardingTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (AppAnimations.animationsEnabled(context)) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppAnimations.animationsEnabled(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = (_controller.value + i * 0.2) % 1.0;
            final opacity = 0.35 + (0.65 * (t < 0.5 ? t * 2 : (1 - t) * 2));
            return Opacity(
              opacity: opacity.clamp(0.35, 1.0),
              child: child,
            );
          },
          child: Container(
            width: 10,
            height: 10,
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingXS),
            decoration: BoxDecoration(
              color: AppColors.textPrimaryDark,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
