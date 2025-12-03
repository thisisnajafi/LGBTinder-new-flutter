import '../../../profile/data/models/user_profile.dart';

/// Discovery profile model (simplified user profile for discovery)
class DiscoveryProfile {
  final int id;
  final String firstName;
  final String? lastName;
  final int? age;
  final String? city;
  final String? country;
  final String? gender;
  final String? profileBio;
  final int? height;
  final List<String>? imageUrls;
  final String? primaryImageUrl;
  final double? distance;
  final int? compatibilityScore;
  final bool? isSuperliked;
  final DateTime? lastActive;

  DiscoveryProfile({
    required this.id,
    required this.firstName,
    this.lastName,
    this.age,
    this.city,
    this.country,
    this.gender,
    this.profileBio,
    this.height,
    this.imageUrls,
    this.primaryImageUrl,
    this.distance,
    this.compatibilityScore,
    this.isSuperliked,
    this.lastActive,
  });

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    return DiscoveryProfile(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      age: json['age'] as int?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      gender: json['gender'] as String?,
      profileBio: json['profile_bio'] as String?,
      height: json['height'] as int?,
      imageUrls: json['images'] != null
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : null,
      primaryImageUrl: json['primary_image_url'] as String? ?? json['image_url'] as String?,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      compatibilityScore: json['compatibility_score'] as int?,
      isSuperliked: json['is_superliked'] as bool?,
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (age != null) 'age': age,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (gender != null) 'gender': gender,
      if (profileBio != null) 'profile_bio': profileBio,
      if (height != null) 'height': height,
      if (imageUrls != null) 'images': imageUrls,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      if (distance != null) 'distance': distance,
      if (compatibilityScore != null) 'compatibility_score': compatibilityScore,
      if (isSuperliked != null) 'is_superliked': isSuperliked,
      if (lastActive != null) 'last_active': lastActive!.toIso8601String(),
    };
  }
}
