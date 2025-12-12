/// Safe type parsing helpers for age preference
/// FIXED: Task 5.2.1 - Added safe type parsing to prevent crashes
int? _safeParseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _safeParseBoolNullable(dynamic value, {bool? defaultValue}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

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
      minAge: _safeParseIntNullable(json['min_age']),
      maxAge: _safeParseIntNullable(json['max_age']),
      isEnabled: _safeParseBoolNullable(json['is_enabled'], defaultValue: true),
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
