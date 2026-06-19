import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/models/match_reason.dart';

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
  final int? matchPercentage;
  final List<MatchReason> matchReasons;
  final List<String>? interestNames;
  final List<String>? sharedInterestNames;
  final String? jobTitle;
  final String? educationTitle;
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
    this.matchPercentage,
    this.matchReasons = const [],
    this.interestNames,
    this.sharedInterestNames,
    this.jobTitle,
    this.educationTitle,
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
      profileBio: json['profile_bio']?.toString() ?? json['bio']?.toString(),
      height: json['height'] != null ? ((json['height'] is int) ? json['height'] as int : int.tryParse(json['height'].toString())) : null,
      imageUrls: _parseImageUrls(json['images']),
      primaryImageUrl: _resolveImageUrl(
        json['primary_image_url']?.toString() ?? json['image_url']?.toString() ?? json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      ),
      distance: _parseDistance(json),
      compatibilityScore: _parseInt(json['compatibility_score'] ?? json['match_score']),
      matchPercentage: _parseInt(json['match_percentage']),
      matchReasons: _parseMatchReasons(json['match_reasons']),
      interestNames: _parseTitleList(json['interests']),
      sharedInterestNames: _parseStringList(json['shared_interests']),
      jobTitle: _parseFirstTitle(json['jobs']) ?? json['job']?.toString() ?? json['job_title']?.toString(),
      educationTitle: _parseFirstTitle(json['educations']) ?? json['education']?.toString() ?? json['education_title']?.toString(),
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
      if (matchPercentage != null) 'match_percentage': matchPercentage,
      if (matchReasons.isNotEmpty) 'match_reasons': matchReasons.map((e) => e.toJson()).toList(),
      if (interestNames != null) 'interests': interestNames,
      if (sharedInterestNames != null) 'shared_interests': sharedInterestNames,
      if (jobTitle != null) 'job_title': jobTitle,
      if (educationTitle != null) 'education_title': educationTitle,
      if (isSuperliked != null) 'is_superliked': isSuperliked,
      if (isVerified != null) 'is_verified': isVerified,
      if (isPremium != null) 'is_premium': isPremium,
      if (isOnline != null) 'is_online': isOnline,
      if (lastActive != null) 'last_active': lastActive!.toIso8601String(),
    };
  }

  static double? _parseDistance(Map<String, dynamic> json) {
    final raw = json['distance'] ?? json['distance_km'];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static List<MatchReason> _parseMatchReasons(dynamic raw) {
    if (raw == null || raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MatchReason.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.label.isNotEmpty)
        .toList();
  }

  static List<String>? _parseTitleList(dynamic raw) {
    if (raw == null || raw is! List) return null;
    final titles = <String>[];
    for (final item in raw) {
      if (item is Map && item['title'] != null) {
        titles.add(item['title'].toString());
      } else if (item is String && item.isNotEmpty) {
        titles.add(item);
      }
    }
    return titles.isEmpty ? null : titles;
  }

  static List<String>? _parseStringList(dynamic raw) {
    if (raw == null || raw is! List) return null;
    final list = raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return list.isEmpty ? null : list;
  }

  static String? _parseFirstTitle(dynamic raw) {
    final titles = _parseTitleList(raw);
    return titles != null && titles.isNotEmpty ? titles.first : null;
  }

  /// Parse images from API: list of { image_url: string } or list of URL strings.
  static List<String>? _parseImageUrls(dynamic images) {
    if (images == null || images is! List) return null;
    final list = <String>[];
    for (final e in images) {
      if (e is Map && e['image_url'] != null) {
        final url = _resolveImageUrl(e['image_url'].toString());
        if (url != null && url.isNotEmpty) list.add(url);
      } else if (e is String && e.isNotEmpty) {
        final url = _resolveImageUrl(e);
        if (url != null && url.isNotEmpty) list.add(url);
      }
    }
    return list.isEmpty ? null : list;
  }

  /// Return full URL; if [urlOrPath] is relative, prepend storage base URL.
  static String? _resolveImageUrl(String? urlOrPath) {
    if (urlOrPath == null || urlOrPath.isEmpty) return null;
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return urlOrPath;
    }
    final base = ApiEndpoints.storageUrl;
    final path = urlOrPath.startsWith('/') ? urlOrPath : '/$urlOrPath';
    return '$base$path';
  }
}
