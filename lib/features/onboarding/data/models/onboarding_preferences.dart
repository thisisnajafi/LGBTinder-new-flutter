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
      relationshipGoal: json['relationship_goal']?.toString(),
      interests: json['interests'] != null && json['interests'] is List
          ? (json['interests'] as List).map((e) => e.toString()).toList()
          : null,
      preferredGender: json['preferred_gender']?.toString(),
      ageRangeMin: json['age_range_min'] != null ? ((json['age_range_min'] is int) ? json['age_range_min'] as int : int.tryParse(json['age_range_min'].toString())) : null,
      ageRangeMax: json['age_range_max'] != null ? ((json['age_range_max'] is int) ? json['age_range_max'] as int : int.tryParse(json['age_range_max'].toString())) : null,
      maxDistance: json['max_distance'] != null
          ? (json['max_distance'] as num).toDouble()
          : null,
      showMeOnApp: json['show_me_on_app'] == true || json['show_me_on_app'] == 1,
      receiveNotifications: json['receive_notifications'] == true || json['receive_notifications'] == 1,
      customAnswers: json['custom_answers'] != null && json['custom_answers'] is Map
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
      currentStep: json['current_step'] != null ? ((json['current_step'] is int) ? json['current_step'] as int : int.tryParse(json['current_step'].toString()) ?? 0) : 0,
      totalSteps: json['total_steps'] != null ? ((json['total_steps'] is int) ? json['total_steps'] as int : int.tryParse(json['total_steps'].toString()) ?? 5) : 5,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
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
    // Validate required fields
    if (json['step_number'] == null) {
      throw FormatException('OnboardingStep.fromJson: step_number is required but was null');
    }
    if (json['title'] == null) {
      throw FormatException('OnboardingStep.fromJson: title is required but was null');
    }
    if (json['subtitle'] == null) {
      throw FormatException('OnboardingStep.fromJson: subtitle is required but was null');
    }
    
    return OnboardingStep(
      stepNumber: (json['step_number'] is int) ? json['step_number'] as int : int.parse(json['step_number'].toString()),
      title: json['title'].toString(),
      subtitle: json['subtitle'].toString(),
      description: json['description']?.toString(),
      isRequired: json['is_required'] == true || json['is_required'] == 1 || json['is_required'] == null,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      metadata: json['metadata'] != null && json['metadata'] is Map
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
