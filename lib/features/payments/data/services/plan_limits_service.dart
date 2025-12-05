import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/plan_limits.dart';

/// Plan Limits Service Provider
final planLimitsServiceProvider = Provider<PlanLimitsService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PlanLimitsService(apiService);
});

/// Plan Limits Service
/// 
/// Fetches and caches user's plan limits from the backend
class PlanLimitsService {
  final ApiService _apiService;
  
  // Cache for plan limits
  PlanLimits? _cachedLimits;
  DateTime? _lastFetchTime;
  
  // Cache duration (5 minutes)
  static const cacheDuration = Duration(minutes: 5);

  PlanLimitsService(this._apiService);

  /// Get user's plan limits (with caching)
  Future<PlanLimits> getPlanLimits({bool forceRefresh = false}) async {
    try {
      // Check if cache is valid
      if (!forceRefresh && _cachedLimits != null && _lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
        if (timeSinceLastFetch < cacheDuration) {
          return _cachedLimits!;
        }
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiEndpoints.baseUrl}/plan-limits',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        _cachedLimits = PlanLimits.fromJson(response.data!);
        _lastFetchTime = DateTime.now();
        return _cachedLimits!;
      } else {
        throw Exception(response.message ?? 'Failed to fetch plan limits');
      }
    } catch (e) {
      // If we have cached data, return it even if it's stale
      if (_cachedLimits != null) {
        return _cachedLimits!;
      }
      rethrow;
    }
  }

  /// Check a specific limit
  Future<LimitCheckResponse> checkLimit(String limitType) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '${ApiEndpoints.baseUrl}/plan-limits/check',
        data: {'feature': limitType},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return LimitCheckResponse.fromJson(data);
      } else {
        throw Exception(response.message ?? 'Failed to check limit');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has reached swipe limit
  Future<bool> hasReachedSwipeLimit() async {
    try {
      final limits = await getPlanLimits();
      return limits.hasReachedLimit('swipes');
    } catch (e) {
      return false; // Default to allowing swipes if check fails
    }
  }

  /// Check if user has reached like limit
  Future<bool> hasReachedLikeLimit() async {
    try {
      final limits = await getPlanLimits();
      return limits.hasReachedLimit('likes');
    } catch (e) {
      return false;
    }
  }

  /// Check if user has reached superlike limit
  Future<bool> hasReachedSuperlikeLimit() async {
    try {
      final limits = await getPlanLimits();
      return limits.hasReachedLimit('superlikes');
    } catch (e) {
      return false;
    }
  }

  /// Check if user has reached message limit
  Future<bool> hasReachedMessageLimit() async {
    try {
      final limits = await getPlanLimits();
      return limits.hasReachedLimit('messages');
    } catch (e) {
      return false;
    }
  }

  /// Check if user has a specific feature
  Future<bool> hasFeature(String featureName) async {
    try {
      final limits = await getPlanLimits();
      return limits.hasFeature(featureName);
    } catch (e) {
      return false;
    }
  }

  /// Clear cache (useful after subscription change)
  void clearCache() {
    _cachedLimits = null;
    _lastFetchTime = null;
  }

  /// Get cached limits (without API call)
  PlanLimits? getCachedLimits() {
    return _cachedLimits;
  }

  /// Check if cache is valid
  bool isCacheValid() {
    if (_cachedLimits == null || _lastFetchTime == null) {
      return false;
    }
    final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
    return timeSinceLastFetch < cacheDuration;
  }

  /// Increment usage (local update, call after successful action)
  void incrementUsage(String limitType) {
    if (_cachedLimits == null) return;

    // This is a local optimistic update
    // The actual usage will be updated on next fetch
    switch (limitType) {
      case 'swipes':
        _cachedLimits = PlanLimits(
          planInfo: _cachedLimits!.planInfo,
          limits: _cachedLimits!.limits,
          usage: Usage(
            swipes: UsageDetail(
              usedToday: _cachedLimits!.usage.swipes.usedToday + 1,
              limit: _cachedLimits!.usage.swipes.limit,
              remaining: _cachedLimits!.usage.swipes.remaining - 1,
              isUnlimited: _cachedLimits!.usage.swipes.isUnlimited,
            ),
            likes: _cachedLimits!.usage.likes,
            superlikes: _cachedLimits!.usage.superlikes,
            messages: _cachedLimits!.usage.messages,
          ),
          features: _cachedLimits!.features,
          timestamps: _cachedLimits!.timestamps,
        );
        break;
      case 'likes':
        _cachedLimits = PlanLimits(
          planInfo: _cachedLimits!.planInfo,
          limits: _cachedLimits!.limits,
          usage: Usage(
            swipes: _cachedLimits!.usage.swipes,
            likes: UsageDetail(
              usedToday: _cachedLimits!.usage.likes.usedToday + 1,
              limit: _cachedLimits!.usage.likes.limit,
              remaining: _cachedLimits!.usage.likes.remaining - 1,
              isUnlimited: _cachedLimits!.usage.likes.isUnlimited,
            ),
            superlikes: _cachedLimits!.usage.superlikes,
            messages: _cachedLimits!.usage.messages,
          ),
          features: _cachedLimits!.features,
          timestamps: _cachedLimits!.timestamps,
        );
        break;
      case 'superlikes':
        _cachedLimits = PlanLimits(
          planInfo: _cachedLimits!.planInfo,
          limits: _cachedLimits!.limits,
          usage: Usage(
            swipes: _cachedLimits!.usage.swipes,
            likes: _cachedLimits!.usage.likes,
            superlikes: UsageDetail(
              usedToday: _cachedLimits!.usage.superlikes.usedToday + 1,
              limit: _cachedLimits!.usage.superlikes.limit,
              remaining: _cachedLimits!.usage.superlikes.remaining - 1,
              isUnlimited: _cachedLimits!.usage.superlikes.isUnlimited,
            ),
            messages: _cachedLimits!.usage.messages,
          ),
          features: _cachedLimits!.features,
          timestamps: _cachedLimits!.timestamps,
        );
        break;
    }
  }
}

/// Limit Check Response
class LimitCheckResponse {
  final String feature;
  final bool hasReachedLimit;
  final int remaining;
  final int limit;
  final bool isUnlimited;
  final bool upgradeRequired;

  LimitCheckResponse({
    required this.feature,
    required this.hasReachedLimit,
    required this.remaining,
    required this.limit,
    required this.isUnlimited,
    required this.upgradeRequired,
  });

  factory LimitCheckResponse.fromJson(Map<String, dynamic> json) {
    return LimitCheckResponse(
      feature: json['feature'] as String,
      hasReachedLimit: json['has_reached_limit'] as bool,
      remaining: json['remaining'] as int,
      limit: json['limit'] as int,
      isUnlimited: json['is_unlimited'] as bool,
      upgradeRequired: json['upgrade_required'] as bool? ?? false,
    );
  }
}

/// State Notifier Provider for Plan Limits
final planLimitsProvider = StateNotifierProvider<PlanLimitsNotifier, AsyncValue<PlanLimits>>((ref) {
  final service = ref.watch(planLimitsServiceProvider);
  return PlanLimitsNotifier(service);
});

/// Plan Limits Notifier
class PlanLimitsNotifier extends StateNotifier<AsyncValue<PlanLimits>> {
  final PlanLimitsService _service;

  PlanLimitsNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchLimits();
  }

  /// Fetch plan limits
  Future<void> fetchLimits({bool forceRefresh = false}) async {
    if (!forceRefresh && _service.isCacheValid()) {
      final cached = _service.getCachedLimits();
      if (cached != null) {
        state = AsyncValue.data(cached);
        return;
      }
    }

    state = const AsyncValue.loading();
    try {
      final limits = await _service.getPlanLimits(forceRefresh: forceRefresh);
      state = AsyncValue.data(limits);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh limits (force fetch from API)
  Future<void> refresh() async {
    await fetchLimits(forceRefresh: true);
  }

  /// Increment usage locally (optimistic update)
  void incrementUsage(String limitType) {
    _service.incrementUsage(limitType);
    state.whenData((limits) {
      state = AsyncValue.data(limits);
    });
  }

  /// Clear cache
  void clearCache() {
    _service.clearCache();
    state = const AsyncValue.loading();
  }
}

