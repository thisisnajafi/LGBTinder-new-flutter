import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/onboarding_page_view.dart';

/// Main onboarding screen
/// Displays the full onboarding flow with multiple pages
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    // Load existing onboarding data if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).loadOnboardingData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    return AnimatedOnboardingPageView(
      pages: _buildOnboardingPages(),
      onComplete: _onOnboardingComplete,
      onSkip: _onOnboardingSkip,
      showProgressIndicator: true,
      showNavigationButtons: true,
      allowSwipe: true,
    );
  }

  List<OnboardingPage> _buildOnboardingPages() {
    return [
      // Welcome page
      LGBTOnboardingPage(
        title: 'Welcome to LGBTFinder',
        subtitle: 'Find meaningful connections in the LGBTQ+ community',
        description: 'Connect with people who share your values and interests in a safe, inclusive environment.',
        iconData: Icons.favorite,
        actions: [
          ElevatedButton(
            onPressed: () {
              // Continue to next page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),

      // What are you looking for?
      OnboardingPage(
        title: 'What brings you here?',
        subtitle: 'Tell us what kind of connection you\'re seeking',
        description: 'Whether you\'re looking for friendship, romance, or something in between, we\'ve got you covered.',
        iconData: Icons.search,
      ),

      // Your interests
      OnboardingPage(
        title: 'Share your interests',
        subtitle: 'Help us find people with similar passions',
        description: 'Select topics that interest you to discover like-minded individuals in your area.',
        iconData: Icons.interests,
      ),

      // Who do you want to meet?
      OnboardingPage(
        title: 'Who do you want to connect with?',
        subtitle: 'Set your preferences for better matches',
        description: 'Choose who you\'d like to see in your discovery feed.',
        iconData: Icons.people,
      ),

      // Age preferences
      OnboardingPage(
        title: 'Age preferences',
        subtitle: 'Who would you like to meet?',
        description: 'Set your preferred age range to find compatible connections.',
        iconData: Icons.calendar_today,
      ),

      // Location preferences
      OnboardingPage(
        title: 'Location settings',
        subtitle: 'How far are you willing to travel?',
        description: 'Set your distance preferences to find people in your area.',
        iconData: Icons.location_on,
      ),

      // Almost done!
      PrideOnboardingPage(
        title: 'You\'re all set!',
        subtitle: 'Get ready to discover amazing connections',
        description: 'Your preferences have been saved. Now let\'s find your perfect match!',
        iconData: Icons.celebration,
      ),
    ];
  }

  void _onOnboardingComplete() {
    // Navigate to main app
    context.go('/discover');
  }

  void _onOnboardingSkip() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Onboarding?'),
        content: const Text(
          'You can always set up your preferences later in Settings. '
          'Would you like to skip for now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _skipOnboarding();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _skipOnboarding() async {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    await onboardingNotifier.skipOnboarding();
    context.go('/discover');
  }
}

/// Quick onboarding screen for returning users
class QuickOnboardingScreen extends ConsumerWidget {
  const QuickOnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/illustration
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.lgbtGradient,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Welcome back text
              Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Your preferences are saved. Ready to discover?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/discover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Update preferences button
              TextButton(
                onPressed: () => context.go('/onboarding/preferences'),
                child: Text(
                  'Update Preferences',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
