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
      isComplete: json['is_complete'] == true || json['is_complete'] == 1,
      profileCompleted: json['profile_completed'] == true || json['profile_completed'] == 1,
      needsProfileCompletion: json['needs_profile_completion'] == true || json['needs_profile_completion'] == 1 || json['needs_profile_completion'] == null,
      missingFields: json['missing_fields'] != null && json['missing_fields'] is List
          ? (json['missing_fields'] as List).map((field) => field.toString()).toList()
          : [],
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
