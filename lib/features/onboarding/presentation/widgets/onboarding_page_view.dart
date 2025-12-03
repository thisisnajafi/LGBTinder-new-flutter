import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_page.dart';

/// Onboarding page view widget
/// PageView wrapper for onboarding flow with navigation and progress indicators
class OnboardingPageView extends ConsumerStatefulWidget {
  final List<OnboardingPage> pages;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final bool showProgressIndicator;
  final bool showNavigationButtons;
  final bool allowSwipe;
  final Duration animationDuration;

  const OnboardingPageView({
    Key? key,
    required this.pages,
    this.onComplete,
    this.onSkip,
    this.showProgressIndicator = true,
    this.showNavigationButtons = true,
    this.allowSwipe = true,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  ConsumerState<OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends ConsumerState<OnboardingPageView> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (widget.onSkip != null)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Progress indicator
            if (widget.showProgressIndicator)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / widget.pages.length,
                  backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: widget.allowSwipe
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: widget.pages.length,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  return widget.pages[index];
                },
              ),
            ),

            // Navigation buttons
            if (widget.showNavigationButtons)
              _buildNavigationButtons(context, ref, onboardingState),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, WidgetRef ref, OnboardingState onboardingState) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == widget.pages.length - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          if (_currentPage > 0)
            TextButton(
              onPressed: _previousPage,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Previous',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(width: 100), // Spacer for alignment

          // Page indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              widget.pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.primaryLight
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Next/Complete button
          ElevatedButton(
            onPressed: isLastPage ? _handleComplete : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              isLastPage ? 'Get Started' : 'Next',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < widget.pages.length - 1) {
      _pageController.nextPage(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleComplete() async {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    final success = await onboardingNotifier.completeOnboarding();

    if (success && widget.onComplete != null) {
      widget.onComplete!();
    }
  }
}

/// Enhanced onboarding page view with animations
class AnimatedOnboardingPageView extends OnboardingPageView {
  final Curve animationCurve;

  const AnimatedOnboardingPageView({
    Key? key,
    required List<OnboardingPage> pages,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
    bool showProgressIndicator = true,
    bool showNavigationButtons = true,
    bool allowSwipe = true,
    Duration animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  }) : super(
          key: key,
          pages: pages,
          onComplete: onComplete,
          onSkip: onSkip,
          showProgressIndicator: showProgressIndicator,
          showNavigationButtons: showNavigationButtons,
          allowSwipe: allowSwipe,
          animationDuration: animationDuration,
        );

  @override
  ConsumerState<AnimatedOnboardingPageView> createState() => _AnimatedOnboardingPageViewState();
}

class _AnimatedOnboardingPageViewState extends ConsumerState<AnimatedOnboardingPageView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: super.build(context, ref),
    );
  }
}

/// Onboarding page view with auto-advance functionality
class AutoAdvanceOnboardingPageView extends OnboardingPageView {
  final Duration autoAdvanceDuration;

  const AutoAdvanceOnboardingPageView({
    Key? key,
    required List<OnboardingPage> pages,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
    bool showProgressIndicator = true,
    bool showNavigationButtons = true,
    bool allowSwipe = true,
    Duration animationDuration = const Duration(milliseconds: 300),
    this.autoAdvanceDuration = const Duration(seconds: 3),
  }) : super(
          key: key,
          pages: pages,
          onComplete: onComplete,
          onSkip: onSkip,
          showProgressIndicator: showProgressIndicator,
          showNavigationButtons: showNavigationButtons,
          allowSwipe: allowSwipe,
          animationDuration: animationDuration,
        );

  @override
  ConsumerState<AutoAdvanceOnboardingPageView> createState() => _AutoAdvanceOnboardingPageViewState();
}

class _AutoAdvanceOnboardingPageViewState extends ConsumerState<AutoAdvanceOnboardingPageView>
    with TickerProviderStateMixin {
  late Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _startAutoAdvanceTimer();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _startAutoAdvanceTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(widget.autoAdvanceDuration, () {
      if (mounted && _currentPage < widget.pages.length - 1) {
        _nextPage();
        _startAutoAdvanceTimer(); // Restart timer for next page
      }
    });
  }

  @override
  void _nextPage() {
    super._nextPage();
    _startAutoAdvanceTimer();
  }

  @override
  void _previousPage() {
    super._previousPage();
    _startAutoAdvanceTimer();
  }
}

/// Import for Timer
import 'dart:async';
