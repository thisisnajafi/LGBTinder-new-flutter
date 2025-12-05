/// Compatibility score model
class CompatibilityScore {
  final int userId;
  final int score;
  final Map<String, dynamic>? breakdown;
  final List<String>? commonInterests;
  final List<String>? matchingTraits;

  CompatibilityScore({
    required this.userId,
    required this.score,
    this.breakdown,
    this.commonInterests,
    this.matchingTraits,
  });

  factory CompatibilityScore.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['user_id'] == null) {
      throw FormatException('CompatibilityScore.fromJson: user_id is required but was null');
    }
    
    // Get score from multiple possible fields
    int score = 0;
    if (json['score'] != null) {
      score = (json['score'] is int) ? json['score'] as int : int.tryParse(json['score'].toString()) ?? 0;
    } else if (json['compatibility_score'] != null) {
      score = (json['compatibility_score'] is int) ? json['compatibility_score'] as int : int.tryParse(json['compatibility_score'].toString()) ?? 0;
    }
    
    return CompatibilityScore(
      userId: (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      score: score,
      breakdown: json['breakdown'] != null && json['breakdown'] is Map
          ? Map<String, dynamic>.from(json['breakdown'] as Map)
          : null,
      commonInterests: json['common_interests'] != null && json['common_interests'] is List
          ? (json['common_interests'] as List).map((e) => e.toString()).toList()
          : null,
      matchingTraits: json['matching_traits'] != null && json['matching_traits'] is List
          ? (json['matching_traits'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'score': score,
      if (breakdown != null) 'breakdown': breakdown,
      if (commonInterests != null) 'common_interests': commonInterests,
      if (matchingTraits != null) 'matching_traits': matchingTraits,
    };
  }
}
