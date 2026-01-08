import 'package:equatable/equatable.dart';

/// Represents a Google Play purchase history item from the API
class GooglePlayPurchaseHistory extends Equatable {
  final int id;
  final String productId;
  final String type; // 'subscription' or 'one_time'
  final String status; // 'completed', 'pending', 'cancelled', 'refunded'
  final double? price;
  final String? currency;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final bool autoRenewing;
  final String? orderId;
  final Map<String, dynamic>? subscription;
  final Map<String, dynamic>? superlikePack;
  final Map<String, dynamic>? marketingAttribution;

  const GooglePlayPurchaseHistory({
    required this.id,
    required this.productId,
    required this.type,
    required this.status,
    this.price,
    this.currency,
    this.purchaseDate,
    this.expiryDate,
    this.autoRenewing = false,
    this.orderId,
    this.subscription,
    this.superlikePack,
    this.marketingAttribution,
  });

  factory GooglePlayPurchaseHistory.fromJson(Map<String, dynamic> json) {
    return GooglePlayPurchaseHistory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      productId: json['product_id']?.toString() ?? json['google_product_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'one_time',
      status: json['status']?.toString() ?? json['purchase_state']?.toString() ?? 'pending',
      price: json['price'] != null
          ? (json['price'] is num ? json['price'].toDouble() : double.tryParse(json['price'].toString()))
          : (json['price_amount_micros'] != null ? (json['price_amount_micros'] as int) / 1000000.0 : null),
      currency: json['currency']?.toString() ?? json['price_currency_code']?.toString() ?? 'USD',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString())
          : (json['purchase_time'] != null ? DateTime.tryParse(json['purchase_time'].toString()) : null),
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : (json['expiry_time'] != null ? DateTime.tryParse(json['expiry_time'].toString()) : null),
      autoRenewing: json['auto_renewing'] == true || json['auto_renewing'] == 1,
      orderId: json['order_id']?.toString(),
      subscription: json['subscription'] != null && json['subscription'] is Map
          ? Map<String, dynamic>.from(json['subscription'] as Map)
          : null,
      superlikePack: json['superlike_pack'] != null && json['superlike_pack'] is Map
          ? Map<String, dynamic>.from(json['superlike_pack'] as Map)
          : null,
      marketingAttribution: json['marketing_attribution'] != null && json['marketing_attribution'] is Map
          ? Map<String, dynamic>.from(json['marketing_attribution'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'type': type,
      'status': status,
      'price': price,
      'currency': currency,
      'purchase_date': purchaseDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'auto_renewing': autoRenewing,
      'order_id': orderId,
      if (subscription != null) 'subscription': subscription,
      if (superlikePack != null) 'superlike_pack': superlikePack,
      if (marketingAttribution != null) 'marketing_attribution': marketingAttribution,
    };
  }

  /// Get formatted price with currency
  String get formattedPrice {
    if (price == null) return 'N/A';
    return '${price!.toStringAsFixed(2)} ${currency ?? 'USD'}';
  }

  /// Check if purchase is active
  bool get isActive {
    if (status != 'completed') return false;
    if (expiryDate == null) return true; // One-time purchases don't expire
    return DateTime.now().isBefore(expiryDate!);
  }

  /// Check if purchase is a subscription
  bool get isSubscription => type == 'subscription';

  /// Get product name from subscription or superlike pack
  String get productName {
    if (subscription != null && subscription!['plan'] != null) {
      return subscription!['plan']['title']?.toString() ?? productId;
    }
    if (superlikePack != null) {
      return superlikePack!['name']?.toString() ?? 'Superlike Pack';
    }
    return productId;
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    type,
    status,
    price,
    currency,
    purchaseDate,
    expiryDate,
    autoRenewing,
    orderId,
  ];
}
