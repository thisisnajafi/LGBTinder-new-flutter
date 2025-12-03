/// Profile completion status model
class ProfileCompletion {
  final bool isComplete;
  final bool profileCompleted;
  final bool needsProfileCompletion;
  final List<String> missingFields;

  ProfileCompletion({
    required this.isComplete,
    required this.profileCompleted,
    required this.needsProfileCompletion,
    required this.missingFields,
  });

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) {
    return ProfileCompletion(
      isComplete: json['is_complete'] as bool? ?? false,
      profileCompleted: json['profile_completed'] as bool? ?? false,
      needsProfileCompletion: json['needs_profile_completion'] as bool? ?? true,
      missingFields: (json['missing_fields'] as List<dynamic>?)
              ?.map((field) => field as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_complete': isComplete,
      'profile_completed': profileCompleted,
      'needs_profile_completion': needsProfileCompletion,
      'missing_fields': missingFields,
    };
  }
}
