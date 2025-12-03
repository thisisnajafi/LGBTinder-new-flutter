/// Age preference model - represents user's preferred age range for discovery
class AgePreference {
  final int? minAge;
  final int? maxAge;
  final bool? isEnabled;

  AgePreference({
    this.minAge,
    this.maxAge,
    this.isEnabled = true,
  });

  factory AgePreference.fromJson(Map<String, dynamic> json) {
    return AgePreference(
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (minAge != null) 'min_age': minAge,
      if (maxAge != null) 'max_age': maxAge,
      'is_enabled': isEnabled,
    };
  }

  /// Get formatted age range string
  String get formattedRange {
    if (minAge != null && maxAge != null) {
      return '$minAge - $maxAge years';
    } else if (minAge != null) {
      return '$minAge+ years';
    } else if (maxAge != null) {
      return 'Up to $maxAge years';
    }
    return 'Any age';
  }

  /// Check if an age falls within the preference range
  bool isAgeInRange(int age) {
    if (!isEnabled!) return true;

    bool meetsMin = minAge == null || age >= minAge!;
    bool meetsMax = maxAge == null || age <= maxAge!;

    return meetsMin && meetsMax;
  }

  /// Create a copy with updated values
  AgePreference copyWith({
    int? minAge,
    int? maxAge,
    bool? isEnabled,
  }) {
    return AgePreference(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
