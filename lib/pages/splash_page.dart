// Screen: SplashPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/spacing_constants.dart';
import '../widgets/loading/circular_progress.dart';
import '../widgets/navbar/lgbtfinder_logo.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/api_providers.dart';
import '../shared/services/token_storage_service.dart';
import '../shared/services/onboarding_service.dart';
import '../features/user/providers/user_providers.dart';
import '../shared/models/api_error.dart';

/// Splash page - App startup screen with logo and loading
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate app initialization
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Check authentication status
      final tokenStorage = ref.read(tokenStorageServiceProvider);
      final isAuthenticated = await tokenStorage.isAuthenticated();
      print('🔐 Authentication status: $isAuthenticated');

      // Check onboarding completion status and first launch
      final onboardingService = OnboardingService();
      final hasCompletedOnboarding = await onboardingService.isOnboardingCompleted();
      final isFirstLaunch = await onboardingService.isFirstLaunch();

      if (!mounted) return;

      // TEMPORARY: Force navigation to home for testing
      print('🏠 TEMPORARY: Force navigation to home screen');
      if (mounted) {
        context.go('/home');
      }
      return;

      if (!isAuthenticated) {
        print('🚪 Not authenticated - going to welcome screen');
        // Not authenticated - go to welcome screen
        if (mounted) {
          context.go('/welcome');
        }
        return;
      }

      print('✅ User is authenticated - fetching user info');

      // User is authenticated - check profile and onboarding status
      try {
        // Try to get user info to check profile completion
        final userService = ref.read(userServiceProvider);
        final userInfo = await userService.getUserInfo();
        
        // Check if profile is complete (has required fields)
        // Temporarily not requiring gender for testing
        final isProfileComplete = userInfo.country != null &&
                                  userInfo.city != null &&
                                  // userInfo.gender != null &&
                                  userInfo.birthDate != null;

        print('👤 Profile completion check:');
        print('  - Country: ${userInfo.country}');
        print('  - City: ${userInfo.city}');
        print('  - Gender: ${userInfo.gender}');
        print('  - Birth Date: ${userInfo.birthDate}');
        print('  - Is profile complete: $isProfileComplete');

        if (!mounted) return;

        if (!isProfileComplete) {
          print('⚠️ Profile incomplete - going to profile wizard');
          // Profile incomplete - go to profile wizard
          if (mounted) {
            context.go('/profile-wizard');
          }
          return;
        }

        // Only show onboarding on first launch, not every time it's incomplete
        // This prevents showing onboarding to returning users who skipped it
        print('🎯 Onboarding check: hasCompleted=$hasCompletedOnboarding, isFirstLaunch=$isFirstLaunch');
        if (!hasCompletedOnboarding && isFirstLaunch) {
          print('📚 First launch and onboarding not done - going to onboarding');
          // First launch and onboarding not done - go to onboarding
          if (mounted) {
            context.go('/onboarding');
          }
          return;
        }

        print('🏠 Everything is complete - going to home');
        // Everything is complete - go to home
        if (mounted) {
          print('🚀 Navigating to /home');
          context.go('/home');
        }
      } on ApiError catch (e) {
        print('🚨 ApiError during user info fetch: ${e.code} - ${e.message}');
        // If we get 401/403, token might be invalid - clear and go to welcome
        if (e.code == 401 || e.code == 403) {
          print('🔑 Token invalid - clearing and going to welcome');
          await tokenStorage.clearAllTokens();
          if (mounted) {
            context.go('/welcome');
          }
        } else {
          print('⚠️ Other API error - going to home anyway');
          // Other error - still try to go to home, user can retry
          if (mounted) {
            context.go('/home');
          }
        }
      } catch (e) {
        print('💥 Unexpected error during splash: $e');
        // Unexpected error - go to welcome screen to be safe
        if (mounted) {
          context.go('/welcome');
        }
      }
    } catch (e) {
      // Error checking auth - go to welcome screen
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Rainbow gradient colors (LGBTQ+ Pride flag colors)
    final rainbowGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE40303), // Red
        Color(0xFFFF8C00), // Orange
        Color(0xFFFFED00), // Yellow
        Color(0xFF008026), // Green
        Color(0xFF004DFF), // Blue
        Color(0xFF750787), // Purple
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: rainbowGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: LGBTFinderLogo(size: 80),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // App name
                Text(
                  'LGBTFinder',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Find your perfect match',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Loading indicator
                CircularProgress(
                  size: 40,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
