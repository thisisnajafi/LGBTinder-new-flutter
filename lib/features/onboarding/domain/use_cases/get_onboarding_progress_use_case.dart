import '../../data/repositories/onboarding_repository.dart';

/// Use case for getting onboarding progress
class GetOnboardingProgressUseCase {
  final OnboardingRepository _repository;

  GetOnboardingProgressUseCase(this._repository);

  /// Execute get onboarding progress use case
  Future<Map<String, dynamic>> execute() async {
    try {
      return await _repository.getOnboardingProgress();
    } catch (e) {
      rethrow;
    }
  }
}
