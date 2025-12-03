// Screen: OnboardingScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/buttons/gradient_button.dart';

/// Onboarding screen - Basic onboarding flow with intro slides
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Welcome to LGBTinder',
      description: 'A safe and inclusive space to find meaningful connections',
      icon: Icons.favorite,
      color: AppColors.accentPurple,
    ),
    OnboardingSlide(
      title: 'Discover Matches',
      description: 'Swipe through profiles and find people who share your interests',
      icon: Icons.explore,
      color: AppColors.accentPink,
    ),
    OnboardingSlide(
      title: 'Connect & Chat',
      description: 'Start conversations with your matches and build meaningful relationships',
      icon: Icons.chat_bubble,
      color: AppColors.accentPurple,
    ),
    OnboardingSlide(
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
    if (_currentPage < _slides.length - 1) {
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
    // TODO: Mark onboarding as completed
    // await SharedPreferences.getInstance().then((prefs) {
    //   prefs.setBool('onboarding_completed', true);
    // });
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: AppTypography.button.copyWith(
                      color: secondaryTextColor,
                    ),
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
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlide(
                    slide: slide,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  );
                },
              ),
            ),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                return Container(
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.accentPurple
                        : secondaryTextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            SizedBox(height: AppSpacing.spacingXL),
            // Navigation button
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: GradientButton(
                text: _currentPage == _slides.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _nextPage,
                isFullWidth: true,
                icon: _currentPage == _slides.length - 1
                    ? Icons.arrow_forward
                    : Icons.arrow_forward,
              ),
            ),
            SizedBox(height: AppSpacing.spacingLG),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required OnboardingSlide slide,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.spacingXXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  slide.color,
                  slide.color.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          // Title
          Text(
            slide.title,
            style: AppTypography.h1.copyWith(
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingLG),
          // Description
          Text(
            slide.description,
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
