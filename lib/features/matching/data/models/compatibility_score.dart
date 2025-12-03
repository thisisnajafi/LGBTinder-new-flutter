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
    return CompatibilityScore(
      userId: json['user_id'] as int,
      score: json['score'] as int? ?? json['compatibility_score'] as int? ?? 0,
      breakdown: json['breakdown'] as Map<String, dynamic>?,
      commonInterests: json['common_interests'] != null
          ? (json['common_interests'] as List).map((e) => e.toString()).toList()
          : null,
      matchingTraits: json['matching_traits'] != null
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
