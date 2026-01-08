import '../constants/api_endpoints.dart';
import '../../shared/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';

/// A/B Testing Service
/// Handles A/B test variations and event tracking
/// Part of the Marketing System Implementation (Task 9.2.1)
class ABTestingService {
  final ApiService _apiService;

  ABTestingService(this._apiService);

  // Cache for user variations
  final Map<String, Map<String, dynamic>> _variationCache = {};

  /// Get variation for a feature
  Future<Map<String, dynamic>?> getVariation(String featureKey) async {
    // Check cache first
    if (_variationCache.containsKey(featureKey)) {
      return _variationCache[featureKey];
    }

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.abTestVariation(featureKey),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final data = response.data;
      if (data != null && data['success'] == true && data['variation'] != null) {
        final variation = data['variation'] as Map<String, dynamic>;
        _variationCache[featureKey] = variation;
        return variation;
      }
    } catch (e) {
      // Log error but don't throw
      print('Error fetching A/B test variation: $e');
    }

    return null;
  }

  /// Track A/B test event
  Future<void> trackEvent(
    String featureKey,
    String eventType, {
    double? value,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.abTestTrack,
        data: {
          'feature_key': featureKey,
          'event_type': eventType,
          'value': value ?? 1.0,
          'additional_data': additionalData ?? {},
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      // Log error but don't throw
      print('Error tracking A/B test event: $e');
    }
  }

  /// Get pricing page variation
  Future<Map<String, dynamic>?> getPricingPageVariation() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.abTestPricingPage,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data != null && response.data!['success'] == true) {
        return response.data!['variation'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching pricing page variation: $e');
    }
    return null;
  }

  /// Get banner design variation
  Future<Map<String, dynamic>?> getBannerDesignVariation(String position) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.abTestBanner(position),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data != null && response.data!['success'] == true) {
        return response.data!['variation'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching banner variation: $e');
    }
    return null;
  }

  /// Get notification copy variation
  Future<Map<String, dynamic>?> getNotificationCopyVariation(String templateSlug) async {
    return await getVariation('marketing_notification_copy_$templateSlug');
  }

  /// Get promo offer variation
  Future<Map<String, dynamic>?> getPromoOfferVariation() async {
    return await getVariation('marketing_promo_offer');
  }

  /// Track conversion
  Future<void> trackConversion(
    String testType,
    String conversionType, {
    double? value,
  }) async {
    await trackEvent(
      'marketing_$testType',
      'conversion',
      value: value,
      additionalData: {'conversion_type': conversionType},
    );
  }

  /// Track click
  Future<void> trackClick(String testType, String element) async {
    await trackEvent(
      'marketing_$testType',
      'click',
      additionalData: {'element': element},
    );
  }

  /// Track view
  Future<void> trackView(String testType) async {
    await trackEvent(
      'marketing_$testType',
      'view',
    );
  }

  /// Clear cache (useful for testing or when user changes)
  void clearCache() {
    _variationCache.clear();
  }

  /// Clear specific feature cache
  void clearFeatureCache(String featureKey) {
    _variationCache.remove(featureKey);
  }
}

/// Provider for ABTestingService
final abTestingServiceProvider = Provider<ABTestingService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ABTestingService(apiService);
});
