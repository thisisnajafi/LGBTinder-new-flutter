/// Matching/Discovery preferences — age range, distance, discovery visibility.
/// Persisted via GET/PUT /api/preferences/matching.
class MatchingPreferences {
  final int ageMin;
  final int ageMax;
  final double distance;
  final String discoveryVisibility; // 'everyone' | 'people_i_like' | 'hidden'

  const MatchingPreferences({
    this.ageMin = 18,
    this.ageMax = 100,
    this.distance = 50,
    this.discoveryVisibility = 'everyone',
  });

  factory MatchingPreferences.fromJson(Map<String, dynamic> json) {
    return MatchingPreferences(
      ageMin: (json['age_min'] is int)
          ? json['age_min'] as int
          : int.tryParse(json['age_min']?.toString() ?? '18') ?? 18,
      ageMax: (json['age_max'] is int)
          ? json['age_max'] as int
          : int.tryParse(json['age_max']?.toString() ?? '100') ?? 100,
      distance: (json['distance'] is num)
          ? (json['distance'] as num).toDouble()
          : double.tryParse(json['distance']?.toString() ?? '50') ?? 50,
      discoveryVisibility:
          json['discovery_visibility']?.toString() ?? 'everyone',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age_min': ageMin,
      'age_max': ageMax,
      'distance': distance,
      'discovery_visibility': discoveryVisibility,
    };
  }

  MatchingPreferences copyWith({
    int? ageMin,
    int? ageMax,
    double? distance,
    String? discoveryVisibility,
  }) {
    return MatchingPreferences(
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      distance: distance ?? this.distance,
      discoveryVisibility: discoveryVisibility ?? this.discoveryVisibility,
    );
  }
}
