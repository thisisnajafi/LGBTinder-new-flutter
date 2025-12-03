import '../../domain/services/onboarding_service.dart';
import '../models/onboarding_preferences.dart';
import '../models/onboarding_progress.dart';

/// Onboarding repository - wraps OnboardingService for use in use cases
class OnboardingRepository {
  final OnboardingService _onboardingService;

  OnboardingRepository(this._onboardingService);

  /// Get onboarding preferences
  Future<OnboardingPreferences> getOnboardingPreferences() async {
    return await _onboardingService.getOnboardingPreferences();
  }

  /// Save onboarding preferences
  Future<OnboardingPreferences> saveOnboardingPreferences(
    OnboardingPreferences preferences,
  ) async {
    return await _onboardingService.saveOnboardingPreferences(preferences);
  }

  /// Complete onboarding
  Future<bool> completeOnboarding(CompleteOnboardingRequest request) async {
    return await _onboardingService.completeOnboarding(request);
  }

  /// Skip onboarding
  Future<bool> skipOnboarding() async {
    return await _onboardingService.skipOnboarding();
  }

  /// Get onboarding progress
  Future<OnboardingProgress> getOnboardingProgress() async {
    return await _onboardingService.getOnboardingProgress();
  }

  /// Update onboarding step
  Future<OnboardingProgress> updateOnboardingStep(int stepNumber) async {
    return await _onboardingService.updateOnboardingStep(stepNumber);
  }

  /// Reset onboarding
  Future<void> resetOnboarding() async {
    return await _onboardingService.resetOnboarding();
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    return await _onboardingService.hasCompletedOnboarding();
  }
}
