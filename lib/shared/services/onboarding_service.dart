import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing onboarding completion status
class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _firstLaunchKey = 'first_launch';
  /// Intro carousel shown once per install (splash -> onboarding -> welcome).
  static const String _introOnboardingSeenKey = 'intro_onboarding_seen';

  /// Whether the user has ever seen the intro onboarding (first-launch carousel).
  /// When false, splash should redirect to /onboarding; when true, to welcome or home.
  Future<bool> hasSeenIntroOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_introOnboardingSeenKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark that the user has seen the intro onboarding (call when they complete or skip).
  Future<void> markIntroOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introOnboardingSeenKey, true);
    } catch (e) {
      // Silently fail
    }
  }

  /// Check if this is the first app launch
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirst = prefs.getBool(_firstLaunchKey) ?? true;
      if (isFirst) {
        // Mark that app has been launched at least once
        await prefs.setBool(_firstLaunchKey, false);
      }
      return isFirst;
    } catch (e) {
      return true; // Default to first launch if error
    }
  }

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Reset onboarding status (for testing or logout)
  Future<void> resetOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
    } catch (e) {
      // Silently fail - not critical
    }
  }
}

