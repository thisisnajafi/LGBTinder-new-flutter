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
  final bool? isVerified;
  final bool? isPremium;
  final bool? isOnline;
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
    this.isVerified,
    this.isPremium,
    this.isOnline,
    this.lastActive,
  });

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    // Get ID - use 0 as fallback
    int profileId = 0;
    if (json['id'] != null) {
      profileId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['user_id'] != null) {
      profileId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    }
    
    // Get first name - provide default if missing
    String firstName = json['first_name']?.toString() ?? 
                       json['name']?.toString() ?? 
                       'User';
    
    return DiscoveryProfile(
      id: profileId,
      firstName: firstName,
      lastName: json['last_name']?.toString(),
      age: json['age'] != null ? ((json['age'] is int) ? json['age'] as int : int.tryParse(json['age'].toString())) : null,
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      gender: json['gender']?.toString(),
      profileBio: json['profile_bio']?.toString(),
      height: json['height'] != null ? ((json['height'] is int) ? json['height'] as int : int.tryParse(json['height'].toString())) : null,
      imageUrls: json['images'] != null && json['images'] is List
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : null,
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      compatibilityScore: json['compatibility_score'] != null ? ((json['compatibility_score'] is int) ? json['compatibility_score'] as int : int.tryParse(json['compatibility_score'].toString())) : null,
      isSuperliked: json['is_superliked'] == true || json['is_superliked'] == 1,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isPremium: json['is_premium'] == true || json['is_premium'] == 1,
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      lastActive: json['last_active'] != null ? DateTime.tryParse(json['last_active'].toString()) : null,
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
      if (isVerified != null) 'is_verified': isVerified,
      if (isPremium != null) 'is_premium': isPremium,
      if (isOnline != null) 'is_online': isOnline,
      if (lastActive != null) 'last_active': lastActive!.toIso8601String(),
    };
  }
}
