import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/campaign_model.dart';
import '../models/banner_model.dart';

/// Marketing service for campaigns, promotions, and banners
/// Part of the Marketing System Implementation (Task 3.2.1)
class MarketingService {
  final ApiService _apiService;

  MarketingService(this._apiService);

  /// Get active promotions for current user
  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final response = await _apiService.get<dynamic>(
        MarketingEndpoints.promotions,
      );

      final data = _extractData(response.data);
      if (data != null && data['promotions'] is List) {
        return (data['promotions'] as List)
            .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Validate a promo code
  Future<PromoValidationResult> validatePromoCode(
    String code, {
    String? productId,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        MarketingEndpoints.validatePromoCode,
        data: {
          'promo_code': code,
          if (productId != null) 'product_id': productId,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return PromoValidationResult.fromJson(response.data ?? {});
    } catch (e) {
      return PromoValidationResult(
        valid: false,
        message: e.toString(),
      );
    }
  }

  /// Apply a promotion to a product
  Future<PromotionResult> applyPromotion({
    required String productId,
    String? promoCode,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        MarketingEndpoints.applyPromotion,
        data: {
          'product_id': productId,
          if (promoCode != null) 'promo_code': promoCode,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return PromotionResult.fromJson(response.data!);
      }
      return PromotionResult(
        success: false,
        originalPrice: 0,
        discount: 0,
        finalPrice: 0,
        error: response.message,
      );
    } catch (e) {
      return PromotionResult(
        success: false,
        originalPrice: 0,
        discount: 0,
        finalPrice: 0,
        error: e.toString(),
      );
    }
  }

  /// Get personalized pricing for current user
  Future<List<PersonalizedPrice>> getPersonalizedPricing() async {
    try {
      final response = await _apiService.get<dynamic>(
        MarketingEndpoints.personalizedPricing,
      );

      final data = _extractData(response.data);
      if (data != null && data['plans'] is List) {
        return (data['plans'] as List)
            .map((e) => PersonalizedPrice.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get price for specific product
  Future<PersonalizedPrice?> getProductPrice(String productId) async {
    try {
      final response = await _apiService.get<dynamic>(
        '${MarketingEndpoints.productPrice}/$productId',
      );

      final data = _extractData(response.data);
      if (data != null) {
        return PersonalizedPrice.fromJson(data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get public promo codes
  Future<List<String>> getPublicPromoCodes() async {
    try {
      final response = await _apiService.get<dynamic>(
        MarketingEndpoints.publicPromoCodes,
      );

      final data = _extractData(response.data);
      if (data != null && data['promo_codes'] is List) {
        return (data['promo_codes'] as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Track campaign impression
  Future<void> trackImpression(int campaignId) async {
    try {
      await _apiService.post<dynamic>(
        MarketingEndpoints.trackImpression,
        data: {'campaign_id': campaignId},
        fromJson: (json) => json,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block UX
    }
  }

  /// Track campaign click
  Future<void> trackClick(int campaignId) async {
    try {
      await _apiService.post<dynamic>(
        MarketingEndpoints.trackClick,
        data: {'campaign_id': campaignId},
        fromJson: (json) => json,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block UX
    }
  }

  Map<String, dynamic>? _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>?;
      }
      return responseData;
    }
    return null;
  }
}

/// Personalized pricing model
class PersonalizedPrice {
  final String productId;
  final String productName;
  final double originalPrice;
  final double finalPrice;
  final double discount;
  final String? discountReason;
  final List<String> appliedRules;

  PersonalizedPrice({
    required this.productId,
    required this.productName,
    required this.originalPrice,
    required this.finalPrice,
    required this.discount,
    this.discountReason,
    this.appliedRules = const [],
  });

  factory PersonalizedPrice.fromJson(Map<String, dynamic> json) {
    return PersonalizedPrice(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountReason: json['discount_reason']?.toString(),
      appliedRules: (json['applied_rules'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool get hasDiscount => discount > 0;

  String get formattedOriginalPrice => '\$${originalPrice.toStringAsFixed(2)}';
  String get formattedFinalPrice => '\$${finalPrice.toStringAsFixed(2)}';
  String get formattedDiscount => '\$${discount.toStringAsFixed(2)}';
}

/// Marketing API endpoints
class MarketingEndpoints {
  static const String promotions = '/marketing/promotions';
  static const String validatePromoCode = '/marketing/validate-promo';
  static const String applyPromotion = '/marketing/apply-promotion';
  static const String personalizedPricing = '/marketing/pricing';
  static const String productPrice = '/marketing/price';
  static const String publicPromoCodes = '/marketing/promo-codes';
  static const String trackImpression = '/marketing/track-impression';
  static const String trackClick = '/marketing/track-click';
}
