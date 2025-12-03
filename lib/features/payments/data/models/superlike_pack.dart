/// Superlike pack model
class SuperlikePack {
  final int id;
  final String name;
  final String? description;
  final int superlikeCount;
  final double price;
  final String currency;
  final bool isPopular;
  final String? stripePriceId;

  SuperlikePack({
    required this.id,
    required this.name,
    this.description,
    required this.superlikeCount,
    required this.price,
    this.currency = 'usd',
    this.isPopular = false,
    this.stripePriceId,
  });

  factory SuperlikePack.fromJson(Map<String, dynamic> json) {
    return SuperlikePack(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      superlikeCount: json['superlike_count'] as int? ?? json['count'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'usd',
      isPopular: json['is_popular'] as bool? ?? false,
      stripePriceId: json['stripe_price_id'] as String? ?? json['price_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'superlike_count': superlikeCount,
      'price': price,
      'currency': currency,
      'is_popular': isPopular,
      if (stripePriceId != null) 'stripe_price_id': stripePriceId,
    };
  }
}

/// User superlike pack (purchased pack)
class UserSuperlikePack {
  final int id;
  final int packId;
  final String packName;
  final int remainingCount;
  final int totalCount;
  final DateTime purchasedAt;
  final DateTime? expiresAt;

  UserSuperlikePack({
    required this.id,
    required this.packId,
    required this.packName,
    required this.remainingCount,
    required this.totalCount,
    required this.purchasedAt,
    this.expiresAt,
  });

  factory UserSuperlikePack.fromJson(Map<String, dynamic> json) {
    // Handle response format: { data: { total_superlikes: X, packs: [...] } }
    final data = json['data'] != null && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    
    // If this is the user-packs response with total_superlikes
    if (data.containsKey('total_superlikes') && data.containsKey('packs')) {
      final packs = data['packs'] as List?;
      if (packs != null && packs.isNotEmpty) {
        final firstPack = packs.first as Map<String, dynamic>;
        return UserSuperlikePack(
          id: firstPack['id'] as int? ?? 0,
          packId: firstPack['pack_id'] as int? ?? 0,
          packName: firstPack['pack_name'] as String? ?? firstPack['name'] as String? ?? '',
          remainingCount: data['total_superlikes'] as int? ?? 0,
          totalCount: firstPack['total_count'] as int? ?? 0,
          purchasedAt: firstPack['purchased_at'] != null
              ? DateTime.parse(firstPack['purchased_at'] as String)
              : DateTime.now(),
          expiresAt: firstPack['expires_at'] != null
              ? DateTime.parse(firstPack['expires_at'] as String)
              : null,
        );
      }
    }
    
    // Standard format
    return UserSuperlikePack(
      id: data['id'] as int? ?? 0,
      packId: data['pack_id'] as int? ?? 0,
      packName: data['pack_name'] as String? ?? data['name'] as String? ?? '',
      remainingCount: data['remaining_count'] as int? ?? data['remaining'] as int? ?? data['total_superlikes'] as int? ?? 0,
      totalCount: data['total_count'] as int? ?? data['total'] as int? ?? 0,
      purchasedAt: data['purchased_at'] != null
          ? DateTime.parse(data['purchased_at'] as String)
          : DateTime.now(),
      expiresAt: data['expires_at'] != null
          ? DateTime.parse(data['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pack_id': packId,
      'pack_name': packName,
      'remaining_count': remainingCount,
      'total_count': totalCount,
      'purchased_at': purchasedAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }
}

/// Purchase superlike pack request
class PurchaseSuperlikePackRequest {
  final int packId;
  final String? paymentMethod;

  PurchaseSuperlikePackRequest({
    required this.packId,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'pack_id': packId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
    };
  }
}
