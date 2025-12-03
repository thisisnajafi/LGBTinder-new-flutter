/// Onboarding preferences model
class OnboardingPreferences {
  final String? relationshipGoal;
  final List<String>? interests;
  final String? preferredGender;
  final int? ageRangeMin;
  final int? ageRangeMax;
  final double? maxDistance;
  final bool? showMeOnApp;
  final bool? receiveNotifications;
  final Map<String, dynamic>? customAnswers;

  OnboardingPreferences({
    this.relationshipGoal,
    this.interests,
    this.preferredGender,
    this.ageRangeMin,
    this.ageRangeMax,
    this.maxDistance,
    this.showMeOnApp,
    this.receiveNotifications,
    this.customAnswers,
  });

  factory OnboardingPreferences.fromJson(Map<String, dynamic> json) {
    return OnboardingPreferences(
      relationshipGoal: json['relationship_goal'] as String?,
      interests: json['interests'] != null
          ? (json['interests'] as List).map((e) => e.toString()).toList()
          : null,
      preferredGender: json['preferred_gender'] as String?,
      ageRangeMin: json['age_range_min'] as int?,
      ageRangeMax: json['age_range_max'] as int?,
      maxDistance: json['max_distance'] != null
          ? (json['max_distance'] as num).toDouble()
          : null,
      showMeOnApp: json['show_me_on_app'] as bool?,
      receiveNotifications: json['receive_notifications'] as bool?,
      customAnswers: json['custom_answers'] != null
          ? Map<String, dynamic>.from(json['custom_answers'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (relationshipGoal != null) 'relationship_goal': relationshipGoal,
      if (interests != null) 'interests': interests,
      if (preferredGender != null) 'preferred_gender': preferredGender,
      if (ageRangeMin != null) 'age_range_min': ageRangeMin,
      if (ageRangeMax != null) 'age_range_max': ageRangeMax,
      if (maxDistance != null) 'max_distance': maxDistance,
      if (showMeOnApp != null) 'show_me_on_app': showMeOnApp,
      if (receiveNotifications != null) 'receive_notifications': receiveNotifications,
      if (customAnswers != null) 'custom_answers': customAnswers,
    };
  }

  /// Create a copy with updated preferences
  OnboardingPreferences copyWith({
    String? relationshipGoal,
    List<String>? interests,
    String? preferredGender,
    int? ageRangeMin,
    int? ageRangeMax,
    double? maxDistance,
    bool? showMeOnApp,
    bool? receiveNotifications,
    Map<String, dynamic>? customAnswers,
  }) {
    return OnboardingPreferences(
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      interests: interests ?? this.interests,
      preferredGender: preferredGender ?? this.preferredGender,
      ageRangeMin: ageRangeMin ?? this.ageRangeMin,
      ageRangeMax: ageRangeMax ?? this.ageRangeMax,
      maxDistance: maxDistance ?? this.maxDistance,
      showMeOnApp: showMeOnApp ?? this.showMeOnApp,
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      customAnswers: customAnswers ?? this.customAnswers,
    );
  }

  /// Check if onboarding is complete
  bool get isComplete {
    return relationshipGoal != null &&
           interests != null && interests!.isNotEmpty &&
           preferredGender != null &&
           ageRangeMin != null &&
           ageRangeMax != null;
  }

  /// Get completion percentage
  double get completionPercentage {
    int completedFields = 0;
    int totalFields = 7; // relationshipGoal, interests, preferredGender, ageRangeMin, ageRangeMax, maxDistance, showMeOnApp

    if (relationshipGoal != null && relationshipGoal!.isNotEmpty) completedFields++;
    if (interests != null && interests!.isNotEmpty) completedFields++;
    if (preferredGender != null && preferredGender!.isNotEmpty) completedFields++;
    if (ageRangeMin != null) completedFields++;
    if (ageRangeMax != null) completedFields++;
    if (maxDistance != null) completedFields++;
    if (showMeOnApp != null) completedFields++;

    return completedFields / totalFields;
  }
}

/// Onboarding progress model
class OnboardingProgress {
  final int currentStep;
  final int totalSteps;
  final bool isCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;

  OnboardingProgress({
    required this.currentStep,
    required this.totalSteps,
    this.isCompleted = false,
    this.startedAt,
    this.completedAt,
  });

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    return OnboardingProgress(
      currentStep: json['current_step'] as int? ?? 0,
      totalSteps: json['total_steps'] as int? ?? 5,
      isCompleted: json['is_completed'] as bool? ?? false,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_step': currentStep,
      'total_steps': totalSteps,
      'is_completed': isCompleted,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }

  /// Get progress percentage
  double get progressPercentage {
    return currentStep / totalSteps;
  }

  /// Check if current step is valid
  bool get isValidStep {
    return currentStep >= 0 && currentStep <= totalSteps;
  }
}

/// Onboarding step model
class OnboardingStep {
  final int stepNumber;
  final String title;
  final String subtitle;
  final String? description;
  final bool isRequired;
  final bool isCompleted;
  final Map<String, dynamic>? metadata;

  OnboardingStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    this.description,
    this.isRequired = true,
    this.isCompleted = false,
    this.metadata,
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    return OnboardingStep(
      stepNumber: json['step_number'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String?,
      isRequired: json['is_required'] as bool? ?? true,
      isCompleted: json['is_completed'] as bool? ?? false,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'title': title,
      'subtitle': subtitle,
      if (description != null) 'description': description,
      'is_required': isRequired,
      'is_completed': isCompleted,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Complete onboarding request
class CompleteOnboardingRequest {
  final OnboardingPreferences preferences;
  final bool skipRemainingSteps;

  CompleteOnboardingRequest({
    required this.preferences,
    this.skipRemainingSteps = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'preferences': preferences.toJson(),
      'skip_remaining_steps': skipRemainingSteps,
    };
  }
}
