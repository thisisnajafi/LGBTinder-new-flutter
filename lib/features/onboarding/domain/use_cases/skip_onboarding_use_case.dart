import '../../data/repositories/onboarding_repository.dart';

/// Use case for skipping onboarding
class SkipOnboardingUseCase {
  final OnboardingRepository _repository;

  SkipOnboardingUseCase(this._repository);

  /// Execute skip onboarding use case
  Future<void> execute() async {
    try {
      await _repository.skipOnboarding();
    } catch (e) {
      rethrow;
    }
  }
}
