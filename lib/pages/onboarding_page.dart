// Screen: OnboardingPage
// Intro carousel shown once per install (splash -> this -> welcome). View only.
// Layout inspired by minimal onboarding: illustration, dots, title, description. No logo.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../shared/services/onboarding_service.dart';
import '../routes/app_router.dart';

/// Onboarding page - First-time user introduction
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

/// Asset paths for onboarding slide illustrations (one per step). Optional; fallback is icon.
const List<String> _onboardingImageAssets = [
  'assets/images/onboarding/slide_1.png',
  'assets/images/onboarding/slide_2.png',
  'assets/images/onboarding/slide_3.png',
  'assets/images/onboarding/slide_4.png',
];

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to LGBTFinder',
      description: 'A safe and inclusive space to find meaningful connections.',
      icon: Icons.favorite,
      color: AppColors.accentPurple,
    ),
    OnboardingStep(
      title: 'Discover Matches',
      description: 'Swipe through profiles and find people who share your interests.',
      icon: Icons.explore,
      color: AppColors.accentPink,
    ),
    OnboardingStep(
      title: 'Connect & Chat',
      description: 'Start conversations with your matches and build meaningful relationships.',
      icon: Icons.chat_bubble,
      color: AppColors.accentPurple,
    ),
    OnboardingStep(
      title: 'Be Yourself',
      description: 'Express your authentic self in a supportive community.',
      icon: Icons.celebration,
      color: AppColors.accentPink,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.prideGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip only, top-right (no logo)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingLG,
                    vertical: AppSpacing.spacingMD,
                  ),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: AppTypography.button.copyWith(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              // Illustration + text at bottom of image
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingStep(
                      _steps[index],
                      index,
                    );
                  },
                ),
              ),
              // Page indicators (dots)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) {
                    final isActive = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              // Next / Get Started button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.spacingLG,
                  AppSpacing.spacingMD,
                  AppSpacing.spacingLG,
                  AppSpacing.spacingXL,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accentPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                      ),
                    ),
                    child: Text(
                      _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                      style: AppTypography.button.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingStep(OnboardingStep step, int index) {
    final imagePath = index < _onboardingImageAssets.length
        ? _onboardingImageAssets[index]
        : null;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingXL),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.spacingMD),
            // Centered illustration (image or placeholder)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Center(
                child: imagePath != null
                    ? _buildIllustrationImage(imagePath, step)
                    : _buildIllustrationPlaceholder(step),
              ),
            ),
            // Text at bottom of image
            SizedBox(height: AppSpacing.spacingLG),
            Text(
              step.title,
              style: AppTypography.h1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              step.description,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.95),
                height: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingLG),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustrationImage(String assetPath, OnboardingStep step) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => _buildIllustrationPlaceholder(step),
    );
  }

  Widget _buildIllustrationPlaceholder(OnboardingStep step) {
    return Center(
      child: Icon(
        step.icon,
        size: 120,
        color: step.color.withOpacity(0.85),
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
