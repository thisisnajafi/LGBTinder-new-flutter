/// Marketing campaign model
/// Part of the Marketing System Implementation (Task 3.1.1)
class CampaignModel {
  final int id;
  final String name;
  final String? description;
  final String type; // promotional, seasonal, flash_sale, retention, acquisition
  final String status; // draft, scheduled, active, paused, completed
  final DateTime? startDate;
  final DateTime? endDate;
  final List<PromotionModel> promotions;
  final String? uiTheme; // default, valentines, pride, summer
  final List<String> targetSegments;
  final int priority;

  CampaignModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.status,
    this.startDate,
    this.endDate,
    this.promotions = const [],
    this.uiTheme,
    this.targetSegments = const [],
    this.priority = 0,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'promotional',
      status: json['status']?.toString() ?? 'active',
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      promotions: (json['promotions'] as List?)
              ?.map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      uiTheme: json['ui_theme']?.toString(),
      targetSegments: (json['target_segments'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      priority: _parseInt(json['priority']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'type': type,
      'status': status,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'promotions': promotions.map((e) => e.toJson()).toList(),
      if (uiTheme != null) 'ui_theme': uiTheme,
      'target_segments': targetSegments,
      'priority': priority,
    };
  }

  bool get isActive => status == 'active';
  bool get hasEnded => endDate != null && endDate!.isBefore(DateTime.now());

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Promotion model for campaigns
class PromotionModel {
  final int id;
  final int? campaignId;
  final String name;
  final String? description;
  final String type; // discount, bonus, trial, bundle
  final String discountType; // percentage, fixed
  final double discountValue;
  final double? maxDiscount;
  final String? promoCode;
  final bool isPublic;
  final int? maxUses;
  final int? maxUsesPerUser;
  final int timesUsed;
  final double? minimumPurchase;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> applicableProducts;
  final bool isActive;

  PromotionModel({
    required this.id,
    this.campaignId,
    required this.name,
    this.description,
    required this.type,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.promoCode,
    this.isPublic = false,
    this.maxUses,
    this.maxUsesPerUser,
    this.timesUsed = 0,
    this.minimumPurchase,
    this.startDate,
    this.endDate,
    this.applicableProducts = const [],
    this.isActive = true,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: _parseInt(json['id']) ?? 0,
      campaignId: _parseInt(json['campaign_id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'discount',
      discountType: json['discount_type']?.toString() ?? 'percentage',
      discountValue: _parseDouble(json['discount_value']) ?? 0.0,
      maxDiscount: _parseDouble(json['max_discount']),
      promoCode: json['promo_code']?.toString(),
      isPublic: _parseBool(json['is_public']),
      maxUses: _parseInt(json['max_uses']),
      maxUsesPerUser: _parseInt(json['max_uses_per_user']),
      timesUsed: _parseInt(json['times_used']) ?? 0,
      minimumPurchase: _parseDouble(json['minimum_purchase']),
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      applicableProducts: (json['applicable_products'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: _parseBool(json['is_active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (campaignId != null) 'campaign_id': campaignId,
      'name': name,
      if (description != null) 'description': description,
      'type': type,
      'discount_type': discountType,
      'discount_value': discountValue,
      if (maxDiscount != null) 'max_discount': maxDiscount,
      if (promoCode != null) 'promo_code': promoCode,
      'is_public': isPublic,
      if (maxUses != null) 'max_uses': maxUses,
      if (maxUsesPerUser != null) 'max_uses_per_user': maxUsesPerUser,
      'times_used': timesUsed,
      if (minimumPurchase != null) 'minimum_purchase': minimumPurchase,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'applicable_products': applicableProducts,
      'is_active': isActive,
    };
  }

  /// Get formatted discount text
  String get discountText {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    } else {
      return '\$${discountValue.toStringAsFixed(2)} OFF';
    }
  }

  /// Check if promotion is valid (within date range and not maxed out)
  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (maxUses != null && timesUsed >= maxUses!) return false;
    return true;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Result of applying a promotion
class PromotionResult {
  final bool success;
  final double originalPrice;
  final double discount;
  final double finalPrice;
  final PromotionModel? promotion;
  final List<String> bonusItems;
  final String? error;

  PromotionResult({
    required this.success,
    required this.originalPrice,
    required this.discount,
    required this.finalPrice,
    this.promotion,
    this.bonusItems = const [],
    this.error,
  });

  factory PromotionResult.fromJson(Map<String, dynamic> json) {
    return PromotionResult(
      success: json['success'] == true,
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0.0,
      promotion: json['promotion'] != null
          ? PromotionModel.fromJson(json['promotion'] as Map<String, dynamic>)
          : null,
      bonusItems:
          (json['bonus_items'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      error: json['error']?.toString(),
    );
  }
}

/// Promo code validation result
class PromoValidationResult {
  final bool valid;
  final String message;
  final Map<String, dynamic>? discountPreview;

  PromoValidationResult({
    required this.valid,
    required this.message,
    this.discountPreview,
  });

  factory PromoValidationResult.fromJson(Map<String, dynamic> json) {
    return PromoValidationResult(
      valid: json['success'] == true || json['valid'] == true,
      message: json['message']?.toString() ?? '',
      discountPreview: json['data']?['discount_preview'] as Map<String, dynamic>?,
    );
  }
}

