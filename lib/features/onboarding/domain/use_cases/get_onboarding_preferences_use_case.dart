import '../../data/repositories/onboarding_repository.dart';
import '../../data/models/onboarding_preferences.dart';

/// Use Case: GetOnboardingPreferencesUseCase
/// Handles retrieving user's onboarding preferences
class GetOnboardingPreferencesUseCase {
  final OnboardingRepository _onboardingRepository;

  GetOnboardingPreferencesUseCase(this._onboardingRepository);

  /// Execute get onboarding preferences use case
  /// Returns [OnboardingPreferences] with user's current preferences
  Future<OnboardingPreferences> execute() async {
    try {
      return await _onboardingRepository.getOnboardingPreferences();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
