import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/user_analytics.dart';

/// Analytics repository - handles analytics data operations
class AnalyticsRepository {
  final ApiService _apiService;

  AnalyticsRepository(this._apiService);

  /// Get user analytics data
  Future<UserAnalytics> getUserAnalytics({int days = 30}) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.analyticsMyAnalytics,
        queryParameters: {'days': days},
      );

      if (response.isSuccess && response.data != null) {
        return UserAnalytics.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Track user activity
  Future<void> trackActivity({
    required String action,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final requestData = {
        'action': action,
        'metadata': metadata,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.analyticsTrackActivity,
        data: requestData,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET analytics/engagement
  Future<Map<String, dynamic>> getEngagement() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.analyticsEngagement,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET analytics/retention
  Future<Map<String, dynamic>> getRetention() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.analyticsRetention,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET analytics/interactions
  Future<Map<String, dynamic>> getInteractions() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.analyticsInteractions,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET analytics/profile-metrics
  Future<Map<String, dynamic>> getProfileMetrics() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.analyticsProfileMetrics,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }
}

/// Analytics repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AnalyticsRepository(apiService);
});
