import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/onboarding_preferences.dart';
import '../models/onboarding_progress.dart';

/// Onboarding service for managing user onboarding flow
class OnboardingService {
  final ApiService _apiService;

  OnboardingService(this._apiService);

  /// Get onboarding preferences
  Future<OnboardingPreferences> getOnboardingPreferences() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.onboardingPreferences,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return OnboardingPreferences.fromJson(response.data!);
      } else {
        // Return default preferences if none exist
        return OnboardingPreferences();
      }
    } catch (e) {
      // Return default preferences on error
      return OnboardingPreferences();
    }
  }

  /// Save onboarding preferences
  Future<OnboardingPreferences> saveOnboardingPreferences(
    OnboardingPreferences preferences,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.onboardingPreferences,
        data: {'preferences': preferences.toJson()},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return OnboardingPreferences.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Complete onboarding
  Future<bool> completeOnboarding(CompleteOnboardingRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.onboardingComplete,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Skip onboarding
  Future<bool> skipOnboarding() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.onboardingSkip,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get onboarding progress
  Future<OnboardingProgress> getOnboardingProgress() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.onboardingProgress,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return OnboardingProgress.fromJson(response.data!);
      } else {
        return OnboardingProgress(currentStep: 0, totalSteps: 5);
      }
    } catch (e) {
      return OnboardingProgress(currentStep: 0, totalSteps: 5);
    }
  }

  /// Update onboarding step
  Future<OnboardingProgress> updateOnboardingStep(int stepNumber) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.onboardingStep,
        data: {'step_number': stepNumber},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return OnboardingProgress.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reset onboarding
  Future<void> resetOnboarding() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.onboardingReset,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get onboarding progress
  Future<OnboardingProgress> getOnboardingProgress() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.onboardingProgress,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return OnboardingProgress.fromJson(response.data!);
      } else {
        // Return default progress if none exists
        return OnboardingProgress(currentStep: 1, totalSteps: 5);
      }
    } catch (e) {
      // Return default progress on error
      return OnboardingProgress(currentStep: 1, totalSteps: 5);
    }
  }

  /// Skip onboarding
  Future<bool> skipOnboarding() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.onboardingSkip,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response.isSuccess;
    } catch (e) {
      // Allow skipping even if API fails
      return true;
    }
  }

  /// Update onboarding step
  Future<OnboardingProgress> updateOnboardingStep(int stepNumber) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.onboardingStep,
        data: {'step_number': stepNumber},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return OnboardingProgress.fromJson(response.data!);
      } else {
        // Return updated progress
        return OnboardingProgress(
          currentStep: stepNumber,
          totalSteps: 5,
          stepData: {'current_step': stepNumber},
        );
      }
    } catch (e) {
      // Return progress even if API fails
      return OnboardingProgress(
        currentStep: stepNumber,
        totalSteps: 5,
        stepData: {'current_step': stepNumber},
      );
    }
  }

  /// Reset onboarding
  Future<void> resetOnboarding() async {
    try {
      await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.onboardingReset,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      // Reset locally even if API fails
    }
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.onboardingStatus,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['completed'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
