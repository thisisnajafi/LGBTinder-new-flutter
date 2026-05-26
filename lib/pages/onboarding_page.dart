// Screen: OnboardingPage
// Intro carousel: splash -> this -> welcome (first launch only).
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/animation_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_haptics.dart';
import '../core/utils/app_icons.dart';
import '../features/onboarding/widgets/onboarding_intro_hero.dart';
import '../features/onboarding/widgets/onboarding_progress_indicator.dart';
import '../features/onboarding/widgets/onboarding_skip_sheet.dart';
import '../routes/app_router.dart';
import '../shared/services/onboarding_service.dart';
import '../widgets/buttons/gradient_button.dart';

/// Onboarding page - First-time user introduction (4 slides).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingSlide {
  final String title;
  final String description;
  final String iconPath;
  final bool showTypingDots;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.iconPath,
    this.showTypingDots = false,
  });
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  late ConfettiController _confettiController;
  int _currentPage = 0;
  int _direction = 1;

  static const _slides = [
    _OnboardingSlide(
      title: 'Welcome to LGBTFinder',
      description: 'A safe and inclusive space to find meaningful connections.',
      iconPath: 'assets/icons/bold/heart.svg',
    ),
    _OnboardingSlide(
      title: 'Discover Matches',
      description: 'Swipe through profiles and find people who share your interests.',
      iconPath: 'assets/icons/outline/discover.svg',
    ),
    _OnboardingSlide(
      title: 'Connect & Chat',
      description: 'Start conversations with your matches and build meaningful relationships.',
      iconPath: 'assets/icons/outline/message.svg',
      showTypingDots: true,
    ),
    _OnboardingSlide(
      title: 'Be Yourself',
      description: 'Express your authentic self in a supportive community.',
      iconPath: 'assets/icons/outline/flag.svg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    AppHaptics.light();
    if (_currentPage < _slides.length - 1) {
      setState(() => _direction = 1);
      await _pageController.nextPage(
        duration: AppAnimations.transitionPage,
        curve: Curves.easeOutCubic,
      );
    } else {
      AppHaptics.heavy();
      if (AppAnimations.animationsEnabled(context)) {
        _confettiController.play();
      }
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) await _completeOnboarding();
    }
  }

  Future<void> _skipOnboarding() async {
    final skip = await showOnboardingSkipSheet(context);
    if (skip == true && mounted) {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final onboardingService = OnboardingService();
    await onboardingService.markIntroOnboardingSeen();
    if (mounted) {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.prideGradient),
            child: SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: AppColors.lgbtGradient,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    label: 'Skip onboarding',
                    button: true,
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.textPrimaryDark.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingXL),
                  child: OnboardingProgressIndicator(
                    currentStep: _currentPage,
                    totalSteps: _slides.length,
                    style: OnboardingProgressStyle.dots,
                    lightOnDark: true,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _direction = index > _currentPage ? 1 : -1;
                        _currentPage = index;
                      });
                      AppHaptics.selection();
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return AnimatedSwitcher(
                        duration: AppAnimations.transitionPage,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: Offset(_direction * 0.08, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: offset, child: child),
                          );
                        },
                        child: _SlideContent(
                          key: ValueKey(index),
                          slide: _slides[index],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.spacingLG,
                    AppSpacing.spacingMD,
                    AppSpacing.spacingLG,
                    AppSpacing.spacingXL,
                  ),
                  child: Semantics(
                    label: isLast ? 'Get started' : 'Next slide',
                    button: true,
                    child: GradientButton(
                      text: isLast ? 'Get Started' : 'Next',
                      onPressed: _nextPage,
                      usePrideGradient: false,
                    ),
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

class _SlideContent extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideContent({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingXL),
      child: Column(
        children: [
          OnboardingIntroHero(iconPath: slide.iconPath),
          if (slide.showTypingDots) ...[
            SizedBox(height: AppSpacing.spacingMD),
            const OnboardingTypingDots(),
          ],
          SizedBox(height: AppSpacing.spacingLG),
          Text(
            slide.title,
            style: textTheme.displayMedium?.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            slide.description,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimaryDark.withValues(alpha: 0.92),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
