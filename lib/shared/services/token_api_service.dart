import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// API token service (list, current, validate, revoke). For device/session tokens.
class TokenApiService {
  final ApiService _apiService;

  TokenApiService(this._apiService);

  /// GET tokens — list all API tokens. Returns data with tokens list and current_token_id.
  Future<Map<String, dynamic>> getTokens() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.tokens,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {'tokens': [], 'total': 0};
  }

  /// GET tokens/current — current token info.
  Future<Map<String, dynamic>> getCurrentToken() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.tokensCurrent,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET tokens/validate — validate current token.
  Future<Map<String, dynamic>> validateToken() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.tokensValidate,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// DELETE tokens/:id — revoke a token.
  Future<void> revokeToken(int tokenId) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.tokenById(tokenId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }
}
