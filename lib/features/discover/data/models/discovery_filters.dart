/// Discovery filters model
class DiscoveryFilters {
  final int? minAge;
  final int? maxAge;
  final List<int>? preferredGenders;
  final List<int>? interests;
  final List<int>? relationGoals;
  final double? maxDistance;
  final bool? hasPhoto;
  final bool? isVerified;
  final bool? isOnline;
  final String? location;
  final double? latitude;
  final double? longitude;

  DiscoveryFilters({
    this.minAge,
    this.maxAge,
    this.preferredGenders,
    this.interests,
    this.relationGoals,
    this.maxDistance,
    this.hasPhoto,
    this.isVerified,
    this.isOnline,
    this.location,
    this.latitude,
    this.longitude,
  });

  factory DiscoveryFilters.fromJson(Map<String, dynamic> json) {
    return DiscoveryFilters(
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      preferredGenders: json['preferred_genders'] != null
          ? (json['preferred_genders'] as List).map((e) => e as int).toList()
          : null,
      interests: json['interests'] != null
          ? (json['interests'] as List).map((e) => e as int).toList()
          : null,
      relationGoals: json['relation_goals'] != null
          ? (json['relation_goals'] as List).map((e) => e as int).toList()
          : null,
      maxDistance: json['max_distance'] != null
          ? (json['max_distance'] as num).toDouble()
          : null,
      hasPhoto: json['has_photo'] as bool?,
      isVerified: json['is_verified'] as bool?,
      isOnline: json['is_online'] as bool?,
      location: json['location'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (minAge != null) 'min_age': minAge,
      if (maxAge != null) 'max_age': maxAge,
      if (preferredGenders != null && preferredGenders!.isNotEmpty)
        'preferred_genders': preferredGenders,
      if (interests != null && interests!.isNotEmpty) 'interests': interests,
      if (relationGoals != null && relationGoals!.isNotEmpty)
        'relation_goals': relationGoals,
      if (maxDistance != null) 'max_distance': maxDistance,
      if (hasPhoto != null) 'has_photo': hasPhoto,
      if (isVerified != null) 'is_verified': isVerified,
      if (isOnline != null) 'is_online': isOnline,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  /// Check if filters are empty
  bool get isEmpty => toJson().isEmpty;

  /// Create a copy with updated values
  DiscoveryFilters copyWith({
    int? minAge,
    int? maxAge,
    List<int>? preferredGenders,
    List<int>? interests,
    List<int>? relationGoals,
    double? maxDistance,
    bool? hasPhoto,
    bool? isVerified,
    bool? isOnline,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return DiscoveryFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      preferredGenders: preferredGenders ?? this.preferredGenders,
      interests: interests ?? this.interests,
      relationGoals: relationGoals ?? this.relationGoals,
      maxDistance: maxDistance ?? this.maxDistance,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Reset all filters
  DiscoveryFilters reset() {
    return DiscoveryFilters();
  }
}
