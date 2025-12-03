import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Represents a Google Play product (subscription or one-time purchase)
class GooglePlayProduct extends Equatable {
  final String productId;
  final String title;
  final String description;
  final int priceAmountMicros;
  final String priceCurrencyCode;
  final bool isActive;
  final ProductType productType;
  final List<SubscriptionOffer>? subscriptionOffers;

  const GooglePlayProduct({
    required this.productId,
    required this.title,
    required this.description,
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
    this.isActive = true,
    required this.productType,
    this.subscriptionOffers,
  });

  /// Create from ProductDetails (in_app_purchase package)
  factory GooglePlayProduct.fromProductDetails(ProductDetails productDetails) {
    return GooglePlayProduct(
      productId: productDetails.id,
      title: productDetails.title,
      description: productDetails.description,
      priceAmountMicros: int.tryParse(productDetails.price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
      priceCurrencyCode: productDetails.currencyCode ?? 'USD',
      isActive: true,
      productType: productDetails.kind == ProductKind.sub ? ProductType.subscription : ProductType.oneTime,
      subscriptionOffers: productDetails.kind == ProductKind.sub
          ? _parseSubscriptionOffers(productDetails)
          : null,
    );
  }

  /// Create from JSON (API response)
  factory GooglePlayProduct.fromJson(Map<String, dynamic> json) {
    return GooglePlayProduct(
      productId: json['productId'] ?? json['google_product_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priceAmountMicros: json['priceAmountMicros'] ?? json['price_amount_micros'] ?? 0,
      priceCurrencyCode: json['priceCurrencyCode'] ?? json['price_currency_code'] ?? 'USD',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      productType: _parseProductType(json['productType'] ?? json['type']),
      subscriptionOffers: json['subscriptionOfferDetails'] != null
          ? _parseSubscriptionOffersFromJson(json['subscriptionOfferDetails'])
          : null,
    );
  }

  /// Convert to JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'description': description,
      'priceAmountMicros': priceAmountMicros,
      'priceCurrencyCode': priceCurrencyCode,
      'isActive': isActive,
      'productType': productType.toString().split('.').last,
      if (subscriptionOffers != null) 'subscriptionOfferDetails': subscriptionOffers!.map((o) => o.toJson()).toList(),
    };
  }

  /// Get formatted price string
  String get formattedPrice {
    final amount = priceAmountMicros / 1000000;
    return '${priceCurrencyCode.toUpperCase()} ${amount.toStringAsFixed(2)}';
  }

  /// Check if this is a subscription product
  bool get isSubscription => productType == ProductType.subscription;

  /// Check if this is a one-time product
  bool get isOneTime => productType == ProductType.oneTime;

  /// Get the best subscription offer (lowest price or default)
  SubscriptionOffer? get bestOffer {
    if (subscriptionOffers == null || subscriptionOffers!.isEmpty) return null;

    // Return the first offer (in production, you might want to sort by price or priority)
    return subscriptionOffers!.first;
  }

  @override
  List<Object?> get props => [
    productId,
    title,
    description,
    priceAmountMicros,
    priceCurrencyCode,
    isActive,
    productType,
    subscriptionOffers,
  ];

  GooglePlayProduct copyWith({
    String? productId,
    String? title,
    String? description,
    int? priceAmountMicros,
    String? priceCurrencyCode,
    bool? isActive,
    ProductType? productType,
    List<SubscriptionOffer>? subscriptionOffers,
  }) {
    return GooglePlayProduct(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      description: description ?? this.description,
      priceAmountMicros: priceAmountMicros ?? this.priceAmountMicros,
      priceCurrencyCode: priceCurrencyCode ?? this.priceCurrencyCode,
      isActive: isActive ?? this.isActive,
      productType: productType ?? this.productType,
      subscriptionOffers: subscriptionOffers ?? this.subscriptionOffers,
    );
  }
}

/// Product type enum
enum ProductType {
  subscription,
  oneTime;

  static ProductType fromString(String value) {
    return ProductType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProductType.oneTime,
    );
  }
}

/// Represents a subscription offer
class SubscriptionOffer extends Equatable {
  final String offerId;
  final String offerToken;
  final List<PricingPhase> pricingPhases;
  final List<String>? offerTags;

  const SubscriptionOffer({
    required this.offerId,
    required this.offerToken,
    required this.pricingPhases,
    this.offerTags,
  });

  /// Create from JSON
  factory SubscriptionOffer.fromJson(Map<String, dynamic> json) {
    return SubscriptionOffer(
      offerId: json['offerId'] ?? '',
      offerToken: json['offerToken'] ?? '',
      pricingPhases: (json['pricingPhases'] as List<dynamic>?)
          ?.map((phase) => PricingPhase.fromJson(phase))
          .toList() ?? [],
      offerTags: (json['offerTags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'offerToken': offerToken,
      'pricingPhases': pricingPhases.map((phase) => phase.toJson()).toList(),
      if (offerTags != null) 'offerTags': offerTags,
    };
  }

  /// Get the base pricing phase (first phase)
  PricingPhase? get basePricingPhase {
    return pricingPhases.isNotEmpty ? pricingPhases.first : null;
  }

  /// Get formatted price for the base phase
  String get formattedPrice {
    final phase = basePricingPhase;
    if (phase == null) return '';

    final amount = phase.priceAmountMicros / 1000000;
    return '${phase.priceCurrencyCode.toUpperCase()} ${amount.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [offerId, offerToken, pricingPhases, offerTags];
}

/// Represents a pricing phase in a subscription
class PricingPhase extends Equatable {
  final int priceAmountMicros;
  final String priceCurrencyCode;
  final String billingPeriod;
  final String recurrenceMode;
  final int? billingCycleCount;

  const PricingPhase({
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
    required this.billingPeriod,
    required this.recurrenceMode,
    this.billingCycleCount,
  });

  /// Create from JSON
  factory PricingPhase.fromJson(Map<String, dynamic> json) {
    return PricingPhase(
      priceAmountMicros: json['priceAmountMicros'] ?? 0,
      priceCurrencyCode: json['priceCurrencyCode'] ?? 'USD',
      billingPeriod: json['billingPeriod'] ?? 'P1M',
      recurrenceMode: json['recurrenceMode'] ?? 'RECURRING',
      billingCycleCount: json['billingCycleCount'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'priceAmountMicros': priceAmountMicros,
      'priceCurrencyCode': priceCurrencyCode,
      'billingPeriod': billingPeriod,
      'recurrenceMode': recurrenceMode,
      if (billingCycleCount != null) 'billingCycleCount': billingCycleCount,
    };
  }

  /// Get formatted price
  String get formattedPrice {
    final amount = priceAmountMicros / 1000000;
    return '${priceCurrencyCode.toUpperCase()} ${amount.toStringAsFixed(2)}';
  }

  /// Check if this is a recurring phase
  bool get isRecurring => recurrenceMode == 'RECURRING';

  /// Check if this is a one-time phase
  bool get isOneTime => recurrenceMode == 'NON_RECURRING' || recurrenceMode == 'FINITE_RECURRING';

  @override
  List<Object?> get props => [
    priceAmountMicros,
    priceCurrencyCode,
    billingPeriod,
    recurrenceMode,
    billingCycleCount,
  ];
}

// Helper functions
List<SubscriptionOffer> _parseSubscriptionOffers(ProductDetails productDetails) {
  // This would be implemented based on the actual ProductDetails structure
  // For now, return empty list
  return [];
}

List<SubscriptionOffer> _parseSubscriptionOffersFromJson(List<dynamic> offersJson) {
  return offersJson.map((offer) => SubscriptionOffer.fromJson(offer)).toList();
}

ProductType _parseProductType(dynamic value) {
  if (value is String) {
    return ProductType.fromString(value);
  }
  return ProductType.oneTime;
}
