import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// Account API (change-email, change-password, reactivate).
class AccountApiService {
  final ApiService _apiService;

  AccountApiService(this._apiService);

  /// POST account/change-email. Body: new_email, password (or current_password).
  Future<Map<String, dynamic>> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.accountChangeEmail,
      data: {'new_email': newEmail, 'password': password},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST account/change-password.
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.accountChangePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST account/reactivate.
  Future<Map<String, dynamic>> reactivate() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.accountReactivate,
      data: {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }
}
