import '../../data/repositories/onboarding_repository.dart';
import '../../data/models/onboarding_preferences.dart';

/// Use Case: CompleteOnboardingUseCase
/// Handles completing the onboarding process
class CompleteOnboardingUseCase {
  final OnboardingRepository _onboardingRepository;

  CompleteOnboardingUseCase(this._onboardingRepository);

  /// Execute complete onboarding use case
  /// Returns [bool] indicating success
  Future<bool> execute(CompleteOnboardingRequest request) async {
    try {
      // Validate that preferences are complete
      if (!request.preferences.isComplete && !request.skipRemainingSteps) {
        throw Exception('Please complete all required onboarding steps before proceeding');
      }

      return await _onboardingRepository.completeOnboarding(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
