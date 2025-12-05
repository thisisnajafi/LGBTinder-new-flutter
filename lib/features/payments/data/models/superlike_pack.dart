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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('SuperlikePack.fromJson: id is required but was null');
    }
    
    // Get name from multiple possible fields
    String? name = json['name']?.toString() ?? 
                   json['title']?.toString() ?? 
                   json['pack_name']?.toString();
    
    if (name == null || name.isEmpty) {
      throw FormatException('SuperlikePack.fromJson: name (or title/pack_name) is required but was null or empty');
    }
    
    // Get superlike count from multiple possible fields
    int superlikeCount = 0;
    if (json['superlike_count'] != null) {
      superlikeCount = (json['superlike_count'] is int) ? json['superlike_count'] as int : int.tryParse(json['superlike_count'].toString()) ?? 0;
    } else if (json['count'] != null) {
      superlikeCount = (json['count'] is int) ? json['count'] as int : int.tryParse(json['count'].toString()) ?? 0;
    }
    
    return SuperlikePack(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      name: name,
      description: json['description']?.toString(),
      superlikeCount: superlikeCount,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'usd',
      isPopular: json['is_popular'] == true || json['is_popular'] == 1,
      stripePriceId: json['stripe_price_id']?.toString() ?? json['price_id']?.toString(),
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
    final data = json['data'] != null && json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    
    // If this is the user-packs response with total_superlikes
    if (data.containsKey('total_superlikes') && data.containsKey('packs')) {
      final packs = data['packs'];
      if (packs != null && packs is List && packs.isNotEmpty) {
        final firstPack = Map<String, dynamic>.from(packs.first as Map);
        return UserSuperlikePack(
          id: firstPack['id'] != null ? ((firstPack['id'] is int) ? firstPack['id'] as int : int.tryParse(firstPack['id'].toString()) ?? 0) : 0,
          packId: firstPack['pack_id'] != null ? ((firstPack['pack_id'] is int) ? firstPack['pack_id'] as int : int.tryParse(firstPack['pack_id'].toString()) ?? 0) : 0,
          packName: firstPack['pack_name']?.toString() ?? firstPack['name']?.toString() ?? '',
          remainingCount: data['total_superlikes'] != null ? ((data['total_superlikes'] is int) ? data['total_superlikes'] as int : int.tryParse(data['total_superlikes'].toString()) ?? 0) : 0,
          totalCount: firstPack['total_count'] != null ? ((firstPack['total_count'] is int) ? firstPack['total_count'] as int : int.tryParse(firstPack['total_count'].toString()) ?? 0) : 0,
          purchasedAt: firstPack['purchased_at'] != null
              ? (DateTime.tryParse(firstPack['purchased_at'].toString()) ?? DateTime.now())
              : DateTime.now(),
          expiresAt: firstPack['expires_at'] != null
              ? DateTime.tryParse(firstPack['expires_at'].toString())
              : null,
        );
      }
    }
    
    // Standard format
    return UserSuperlikePack(
      id: data['id'] != null ? ((data['id'] is int) ? data['id'] as int : int.tryParse(data['id'].toString()) ?? 0) : 0,
      packId: data['pack_id'] != null ? ((data['pack_id'] is int) ? data['pack_id'] as int : int.tryParse(data['pack_id'].toString()) ?? 0) : 0,
      packName: data['pack_name']?.toString() ?? data['name']?.toString() ?? '',
      remainingCount: data['remaining_count'] != null 
          ? ((data['remaining_count'] is int) ? data['remaining_count'] as int : int.tryParse(data['remaining_count'].toString()) ?? 0)
          : (data['remaining'] != null ? ((data['remaining'] is int) ? data['remaining'] as int : int.tryParse(data['remaining'].toString()) ?? 0) 
          : (data['total_superlikes'] != null ? ((data['total_superlikes'] is int) ? data['total_superlikes'] as int : int.tryParse(data['total_superlikes'].toString()) ?? 0) : 0)),
      totalCount: data['total_count'] != null 
          ? ((data['total_count'] is int) ? data['total_count'] as int : int.tryParse(data['total_count'].toString()) ?? 0)
          : (data['total'] != null ? ((data['total'] is int) ? data['total'] as int : int.tryParse(data['total'].toString()) ?? 0) : 0),
      purchasedAt: data['purchased_at'] != null
          ? (DateTime.tryParse(data['purchased_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      expiresAt: data['expires_at'] != null
          ? DateTime.tryParse(data['expires_at'].toString())
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
