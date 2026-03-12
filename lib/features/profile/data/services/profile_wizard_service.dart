import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';

/// Profile wizard API (current step, step options, save step).
/// Used for profile completion / onboarding when token has profile completion ability.
class ProfileWizardService {
  final ApiService _apiService;

  ProfileWizardService(this._apiService);

  /// GET profile-wizard/current-step. Returns response data (e.g. current_step, steps).
  Future<Map<String, dynamic>> getCurrentStep() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.profileWizardCurrentStep,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
    return response.data ?? {};
  }

  /// GET profile-wizard/step-options/:id. Returns options for the step.
  Future<Map<String, dynamic>> getStepOptions(int stepId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.profileWizardStepOptions(stepId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
    return response.data ?? {};
  }

  /// POST profile-wizard/save-step/:id. Body is step-specific payload.
  Future<Map<String, dynamic>> saveStep(int stepId, Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.profileWizardSaveStep(stepId),
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
    return response.data ?? {};
  }
}
