import '../../data/repositories/onboarding_repository.dart';
import '../../data/models/onboarding_preferences.dart';

/// Use Case: SaveOnboardingPreferencesUseCase
/// Handles saving user's onboarding preferences
class SaveOnboardingPreferencesUseCase {
  final OnboardingRepository _onboardingRepository;

  SaveOnboardingPreferencesUseCase(this._onboardingRepository);

  /// Execute save onboarding preferences use case
  /// Returns [OnboardingPreferences] with saved preferences
  Future<OnboardingPreferences> execute(OnboardingPreferences preferences) async {
    try {
      return await _onboardingRepository.saveOnboardingPreferences(preferences);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
