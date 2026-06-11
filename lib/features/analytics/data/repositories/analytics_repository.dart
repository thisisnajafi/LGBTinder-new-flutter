import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../shared/services/api_service.dart';
import '../models/user_analytics.dart';

/// Analytics repository - handles analytics data operations
class AnalyticsRepository {
  final ApiService _apiService;

  AnalyticsRepository(this._apiService);

  /// Separate client for funnel events — short timeouts, no interceptors/retries.
  static Dio? _trackDio;

  static Dio get _trackingClient {
    return _trackDio ??= Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

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

  /// Track user activity (funnel events). Failures are swallowed — never blocks UX.
  Future<void> trackActivity({
    required String action,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _trackingClient.post(
        ApiEndpoints.analyticsTrackActivity,
        data: {
          'action': action,
          'metadata': metadata,
        },
      );
    } catch (_) {
      // Intentionally silent — analytics must not affect app flows or logs.
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
