import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// Referrals API (stats, code, history, tiers, validate, process-milestone, mark-completed).
class ReferralApiService {
  final ApiService _apiService;

  ReferralApiService(this._apiService);

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      path,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? data]) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      path,
      data: data ?? {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET referrals/stats
  Future<Map<String, dynamic>> getStats() async => _get(ApiEndpoints.referralsStats);

  /// GET referrals/code
  Future<Map<String, dynamic>> getCode() async => _get(ApiEndpoints.referralsCode);

  /// GET referrals/history
  Future<Map<String, dynamic>> getHistory() async => _get(ApiEndpoints.referralsHistory);

  /// GET referrals/tiers
  Future<Map<String, dynamic>> getTiers() async => _get(ApiEndpoints.referralsTiers);

  /// POST referrals/validate-code. Body: code (or referral_code).
  Future<Map<String, dynamic>> validateCode(String code) async =>
      _post(ApiEndpoints.referralsValidateCode, {'code': code});

  /// POST referrals/process-milestone
  Future<Map<String, dynamic>> processMilestone() async =>
      _post(ApiEndpoints.referralsProcessMilestone);

  /// POST referrals/mark-completed. Body: referral_id or referred_user_id.
  Future<Map<String, dynamic>> markCompleted({int? referralId, int? referredUserId}) async {
    final body = <String, dynamic>{};
    if (referralId != null) body['referral_id'] = referralId;
    if (referredUserId != null) body['referred_user_id'] = referredUserId;
    return _post(ApiEndpoints.referralsMarkCompleted, body);
  }
}
