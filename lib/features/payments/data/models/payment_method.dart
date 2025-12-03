/// Payment method model - represents a user's saved payment method
class PaymentMethod {
  final int id;
  final String type; // 'card', 'paypal', 'apple_pay', 'google_pay'
  final String provider; // 'stripe', 'paypal', etc.
  final String lastFour; // last 4 digits for cards
  final String brand; // 'visa', 'mastercard', etc. (for cards)
  final int expiryMonth; // for cards
  final int expiryYear; // for cards
  final bool isDefault;
  final bool isExpired;
  final Map<String, dynamic> metadata; // additional provider-specific data

  PaymentMethod({
    required this.id,
    required this.type,
    required this.provider,
    this.lastFour = '',
    this.brand = '',
    this.expiryMonth = 0,
    this.expiryYear = 0,
    this.isDefault = false,
    this.isExpired = false,
    this.metadata = const {},
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      lastFour: json['last_four'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      expiryMonth: json['expiry_month'] as int? ?? 0,
      expiryYear: json['expiry_year'] as int? ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      isExpired: json['is_expired'] as bool? ?? false,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'provider': provider,
      'last_four': lastFour,
      'brand': brand,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'is_default': isDefault,
      'is_expired': isExpired,
      'metadata': metadata,
    };
  }

  /// Get display name for the payment method
  String get displayName {
    switch (type) {
      case 'card':
        return '${brand.toUpperCase()} **** $lastFour';
      case 'paypal':
        return 'PayPal';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      default:
        return type.toUpperCase();
    }
  }

  /// Check if card is expired
  bool get isCardExpired {
    if (type != 'card') return false;

    final now = DateTime.now();
    final expiryDate = DateTime(expiryYear, expiryMonth + 1, 0); // last day of expiry month
    return now.isAfter(expiryDate);
  }

  /// Get expiry date string
  String get expiryDateString {
    if (type != 'card') return '';
    return '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';
  }
}
