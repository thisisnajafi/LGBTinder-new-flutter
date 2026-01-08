// Screen: EnhancedOnboardingScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/buttons/gradient_button.dart';

/// Enhanced onboarding screen - Enhanced onboarding with more steps and animations
class EnhancedOnboardingScreen extends ConsumerStatefulWidget {
  const EnhancedOnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedOnboardingScreen> createState() => _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState extends ConsumerState<EnhancedOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentPage = 0;

  final List<EnhancedOnboardingSlide> _slides = [
    EnhancedOnboardingSlide(
      title: 'Welcome to LGBTFinder',
      description: 'A safe and inclusive space for the LGBTQ+ community to connect, discover, and build meaningful relationships.',
      icon: Icons.favorite,
      gradient: AppTheme.accentGradient,
    ),
    EnhancedOnboardingSlide(
      title: 'Find Your Perfect Match',
      description: 'Discover amazing people who share your interests, values, and goals. Swipe right to connect!',
      icon: Icons.people,
      gradient: LinearGradient(
        colors: [AppColors.accentPink, AppColors.accentPurple],
      ),
    ),
    EnhancedOnboardingSlide(
      title: 'Build Meaningful Connections',
      description: 'Chat with your matches, share experiences, and build lasting relationships in a supportive environment.',
      icon: Icons.chat_bubble,
      gradient: LinearGradient(
        colors: [AppColors.accentPurple, AppColors.accentPink],
      ),
    ),
    EnhancedOnboardingSlide(
      title: 'Join Our Community',
      description: 'Be part of a vibrant, supportive community that celebrates diversity and promotes authentic connections.',
      icon: Icons.group,
      gradient: AppTheme.accentGradient,
    ),
    EnhancedOnboardingSlide(
      title: 'Safety First',
      description: 'Your privacy and safety are our top priorities. Report, block, and stay in control of your experience.',
      icon: Icons.security,
      gradient: LinearGradient(
        colors: [AppColors.onlineGreen, AppColors.accentPurple],
      ),
    ),
    EnhancedOnboardingSlide(
      title: 'Ready to Start?',
      description: 'Let\'s set up your profile and start your journey to find meaningful connections!',
      icon: Icons.rocket_launch,
      gradient: AppTheme.accentGradient,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _animationController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        _animationController.forward();
      });
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      final onboardingNotifier = ref.read(onboardingProvider.notifier);
      final success = await onboardingNotifier.completeOnboarding();

      if (success && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete onboarding')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing onboarding: $e')),
        );
      }
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
                  _animationController.reset();
                  _animationController.forward();
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildSlide(
                        slide: slide,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: _currentPage == index
                        ? AppTheme.accentGradient
                        : null,
                    color: _currentPage == index
                        ? null
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
                    ? Icons.rocket_launch
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
    required EnhancedOnboardingSlide slide,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.spacingXXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: slide.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              slide.icon,
              size: 72,
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

class EnhancedOnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;

  const EnhancedOnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
