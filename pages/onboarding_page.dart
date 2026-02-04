// Screen: OnboardingPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/app_theme.dart';
import '../widgets/buttons/gradient_button.dart';
import '../screens/onboarding/onboarding_preferences_screen.dart';
import '../shared/services/onboarding_service.dart';
import 'package:go_router/go_router.dart';

/// Onboarding page - First-time user introduction
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to LGBTFinder',
      description: 'A safe and inclusive space to find meaningful connections',
      icon: Icons.favorite,
      color: AppColors.accentPurple,
    ),
    OnboardingStep(
      title: 'Discover Matches',
      description: 'Swipe through profiles and find people who share your interests',
      icon: Icons.explore,
      color: AppColors.accentPink,
    ),
    OnboardingStep(
      title: 'Connect & Chat',
      description: 'Start conversations with your matches and build meaningful relationships',
      icon: Icons.chat_bubble,
      color: AppColors.accentPurple,
    ),
    OnboardingStep(
      title: 'Be Yourself',
      description: 'Express your authentic self in a supportive community',
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
    // Mark onboarding as completed
    final onboardingService = OnboardingService();
    await onboardingService.markOnboardingCompleted();
    
    // Navigate to onboarding preferences screen, then to home
    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const OnboardingPreferencesScreen(),
        ),
      );
      
      // After preferences, navigate to home
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'Skip',
                  style: AppTypography.button.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _buildOnboardingStep(step, isDark);
                },
              ),
            ),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.accentPurple
                        : (isDark
                            ? AppColors.borderMediumDark
                            : AppColors.borderMediumLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            SizedBox(height: AppSpacing.spacingXL),
            // Next/Get Started button
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: GradientButton(
                text: _currentPage == _steps.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _nextPage,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingStep(OnboardingStep step, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.spacingXXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingXXL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  step.color,
                  step.color.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: step.color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              step.icon,
              size: 80,
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          Text(
            step.title,
            style: AppTypography.h1.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            step.description,
            style: AppTypography.body.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
