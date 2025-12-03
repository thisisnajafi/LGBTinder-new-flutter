import 'package:equatable/equatable.dart';

/// Represents a Google Play purchase
class GooglePlayPurchase extends Equatable {
  final String purchaseToken;
  final String productId;
  final PurchaseState purchaseState;
  final String? orderId;
  final DateTime? purchaseTime;
  final DateTime? expiryTime;
  final bool autoRenewing;
  final int? priceAmountMicros;
  final String priceCurrencyCode;
  final AcknowledgementState acknowledgementState;
  final ConsumptionState consumptionState;
  final int? notificationType;
  final int? eventTimeMillis;
  final int? userId;

  const GooglePlayPurchase({
    required this.purchaseToken,
    required this.productId,
    required this.purchaseState,
    this.orderId,
    this.purchaseTime,
    this.expiryTime,
    this.autoRenewing = false,
    this.priceAmountMicros,
    this.priceCurrencyCode = 'USD',
    this.acknowledgementState = AcknowledgementState.yetToBeAcknowledged,
    this.consumptionState = ConsumptionState.yetToBeConsumed,
    this.notificationType,
    this.eventTimeMillis,
    this.userId,
  });

  /// Create from JSON (API response)
  factory GooglePlayPurchase.fromJson(Map<String, dynamic> json) {
    return GooglePlayPurchase(
      purchaseToken: json['google_purchase_token'] ?? '',
      productId: json['google_product_id'] ?? '',
      purchaseState: _parsePurchaseState(json['purchase_state']),
      orderId: json['order_id'],
      purchaseTime: json['purchase_time'] != null
          ? DateTime.parse(json['purchase_time'])
          : null,
      expiryTime: json['expiry_time'] != null
          ? DateTime.parse(json['expiry_time'])
          : null,
      autoRenewing: json['auto_renewing'] ?? false,
      priceAmountMicros: json['price_amount_micros'],
      priceCurrencyCode: json['price_currency_code'] ?? 'USD',
      acknowledgementState: _parseAcknowledgementState(json['acknowledgement_state']),
      consumptionState: _parseConsumptionState(json['consumption_state']),
      notificationType: json['notification_type'],
      eventTimeMillis: json['event_time_millis'],
      userId: json['user_id'],
    );
  }

  /// Convert to JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'google_purchase_token': purchaseToken,
      'google_product_id': productId,
      'purchase_state': purchaseState.toString().split('.').last,
      'order_id': orderId,
      'purchase_time': purchaseTime?.toIso8601String(),
      'expiry_time': expiryTime?.toIso8601String(),
      'auto_renewing': autoRenewing,
      'price_amount_micros': priceAmountMicros,
      'price_currency_code': priceCurrencyCode,
      'acknowledgement_state': acknowledgementState.toString().split('.').last,
      'consumption_state': consumptionState.toString().split('.').last,
      'notification_type': notificationType,
      'event_time_millis': eventTimeMillis,
      'user_id': userId,
    };
  }

  /// Check if purchase is active
  bool get isActive {
    if (purchaseState != PurchaseState.completed) return false;
    if (expiryTime == null) return true; // One-time purchases don't expire
    return DateTime.now().isBefore(expiryTime!);
  }

  /// Check if purchase is a subscription
  bool get isSubscription => productId.contains('_base');

  /// Check if purchase needs acknowledgement
  bool get needsAcknowledgement => acknowledgementState == AcknowledgementState.yetToBeAcknowledged;

  /// Check if purchase needs consumption (for one-time products)
  bool get needsConsumption => consumptionState == ConsumptionState.yetToBeConsumed && !isSubscription;

  @override
  List<Object?> get props => [
    purchaseToken,
    productId,
    purchaseState,
    orderId,
    purchaseTime,
    expiryTime,
    autoRenewing,
    priceAmountMicros,
    priceCurrencyCode,
    acknowledgementState,
    consumptionState,
    notificationType,
    eventTimeMillis,
    userId,
  ];

  GooglePlayPurchase copyWith({
    String? purchaseToken,
    String? productId,
    PurchaseState? purchaseState,
    String? orderId,
    DateTime? purchaseTime,
    DateTime? expiryTime,
    bool? autoRenewing,
    int? priceAmountMicros,
    String? priceCurrencyCode,
    AcknowledgementState? acknowledgementState,
    ConsumptionState? consumptionState,
    int? notificationType,
    int? eventTimeMillis,
    int? userId,
  }) {
    return GooglePlayPurchase(
      purchaseToken: purchaseToken ?? this.purchaseToken,
      productId: productId ?? this.productId,
      purchaseState: purchaseState ?? this.purchaseState,
      orderId: orderId ?? this.orderId,
      purchaseTime: purchaseTime ?? this.purchaseTime,
      expiryTime: expiryTime ?? this.expiryTime,
      autoRenewing: autoRenewing ?? this.autoRenewing,
      priceAmountMicros: priceAmountMicros ?? this.priceAmountMicros,
      priceCurrencyCode: priceCurrencyCode ?? this.priceCurrencyCode,
      acknowledgementState: acknowledgementState ?? this.acknowledgementState,
      consumptionState: consumptionState ?? this.consumptionState,
      notificationType: notificationType ?? this.notificationType,
      eventTimeMillis: eventTimeMillis ?? this.eventTimeMillis,
      userId: userId ?? this.userId,
    );
  }
}

/// Purchase state enum
enum PurchaseState {
  pending,
  completed,
  cancelled,
  refunded;

  static PurchaseState fromString(String value) {
    return PurchaseState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PurchaseState.pending,
    );
  }
}

/// Acknowledgement state enum
enum AcknowledgementState {
  yetToBeAcknowledged,
  acknowledged;
}

/// Consumption state enum (for one-time products)
enum ConsumptionState {
  yetToBeConsumed,
  consumed;
}

// Helper functions
PurchaseState _parsePurchaseState(dynamic value) {
  if (value is String) {
    return PurchaseState.fromString(value);
  }
  return PurchaseState.pending;
}

AcknowledgementState _parseAcknowledgementState(dynamic value) {
  if (value is String) {
    switch (value) {
      case 'acknowledged':
        return AcknowledgementState.acknowledged;
      default:
        return AcknowledgementState.yetToBeAcknowledged;
    }
  }
  return AcknowledgementState.yetToBeAcknowledged;
}

ConsumptionState _parseConsumptionState(dynamic value) {
  if (value is String) {
    switch (value) {
      case 'consumed':
        return ConsumptionState.consumed;
      default:
        return ConsumptionState.yetToBeConsumed;
    }
  }
  return ConsumptionState.yetToBeConsumed;
}
