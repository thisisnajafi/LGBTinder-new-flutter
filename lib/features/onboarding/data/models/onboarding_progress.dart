/// Onboarding progress model
class OnboardingProgress {
  final int currentStep;
  final int totalSteps;
  final bool isCompleted;
  final Map<String, dynamic> stepData;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  OnboardingProgress({
    required this.currentStep,
    required this.totalSteps,
    this.isCompleted = false,
    this.stepData = const {},
    this.startedAt,
    this.completedAt,
    this.metadata,
  });

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    return OnboardingProgress(
      currentStep: json['current_step'] ?? 1,
      totalSteps: json['total_steps'] ?? 5,
      isCompleted: json['is_completed'] ?? false,
      stepData: json['step_data'] ?? {},
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_step': currentStep,
      'total_steps': totalSteps,
      'is_completed': isCompleted,
      'step_data': stepData,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (isCompleted) return 1.0;
    if (totalSteps == 0) return 0.0;
    return (currentStep - 1) / totalSteps;
  }

  /// Check if onboarding is in progress
  bool get isInProgress {
    return !isCompleted && currentStep > 0;
  }

  /// Get remaining steps
  int get remainingSteps {
    return totalSteps - currentStep + 1;
  }

  /// Create a copy with updated progress
  OnboardingProgress copyWith({
    int? currentStep,
    int? totalSteps,
    bool? isCompleted,
    Map<String, dynamic>? stepData,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return OnboardingProgress(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isCompleted: isCompleted ?? this.isCompleted,
      stepData: stepData ?? this.stepData,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Complete onboarding request
class CompleteOnboardingRequest {
  final Map<String, dynamic> finalData;

  CompleteOnboardingRequest({required this.finalData});

  Map<String, dynamic> toJson() {
    return {'final_data': finalData};
  }
}
