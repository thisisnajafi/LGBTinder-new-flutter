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
      id: json['id'] != null ? ((json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0) : 0,
      type: json['type']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      lastFour: json['last_four']?.toString() ?? json['last4']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      expiryMonth: json['expiry_month'] != null ? ((json['expiry_month'] is int) ? json['expiry_month'] as int : int.tryParse(json['expiry_month'].toString()) ?? 0) : 0,
      expiryYear: json['expiry_year'] != null ? ((json['expiry_year'] is int) ? json['expiry_year'] as int : int.tryParse(json['expiry_year'].toString()) ?? 0) : 0,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      isExpired: json['is_expired'] == true || json['is_expired'] == 1,
      metadata: json['metadata'] != null && json['metadata'] is Map
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
