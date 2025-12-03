import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/onboarding_preferences.dart';
import '../domain/use_cases/get_onboarding_preferences_use_case.dart';
import '../domain/use_cases/save_onboarding_preferences_use_case.dart';
import '../domain/use_cases/complete_onboarding_use_case.dart';

/// Onboarding provider - manages onboarding flow and preferences
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final getOnboardingPreferencesUseCase = ref.watch(getOnboardingPreferencesUseCaseProvider);
  final saveOnboardingPreferencesUseCase = ref.watch(saveOnboardingPreferencesUseCaseProvider);
  final completeOnboardingUseCase = ref.watch(completeOnboardingUseCaseProvider);

  return OnboardingNotifier(
    getOnboardingPreferencesUseCase: getOnboardingPreferencesUseCase,
    saveOnboardingPreferencesUseCase: saveOnboardingPreferencesUseCase,
    completeOnboardingUseCase: completeOnboardingUseCase,
  );
});

/// Onboarding state
class OnboardingState {
  final OnboardingPreferences preferences;
  final OnboardingProgress progress;
  final bool isLoading;
  final bool isSaving;
  final bool isCompleting;
  final String? error;
  final bool isCompleted;
  final int currentStep;
  final int totalSteps;

  OnboardingState({
    OnboardingPreferences? preferences,
    OnboardingProgress? progress,
    this.isLoading = false,
    this.isSaving = false,
    this.isCompleting = false,
    this.error,
    this.isCompleted = false,
    this.currentStep = 1,
    this.totalSteps = 5,
  }) : preferences = preferences ?? OnboardingPreferences(),
       progress = progress ?? OnboardingProgress(currentStep: 1, totalSteps: 5);

  OnboardingState copyWith({
    OnboardingPreferences? preferences,
    OnboardingProgress? progress,
    bool? isLoading,
    bool? isSaving,
    bool? isCompleting,
    String? error,
    bool? isCompleted,
    int? currentStep,
    int? totalSteps,
  }) {
    return OnboardingState(
      preferences: preferences ?? this.preferences,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isCompleting: isCompleting ?? this.isCompleting,
      error: error ?? this.error,
      isCompleted: isCompleted ?? this.isCompleted,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }
}

/// Onboarding notifier
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final GetOnboardingPreferencesUseCase _getOnboardingPreferencesUseCase;
  final SaveOnboardingPreferencesUseCase _saveOnboardingPreferencesUseCase;
  final CompleteOnboardingUseCase _completeOnboardingUseCase;

  OnboardingNotifier({
    required GetOnboardingPreferencesUseCase getOnboardingPreferencesUseCase,
    required SaveOnboardingPreferencesUseCase saveOnboardingPreferencesUseCase,
    required CompleteOnboardingUseCase completeOnboardingUseCase,
  }) : _getOnboardingPreferencesUseCase = getOnboardingPreferencesUseCase,
       _saveOnboardingPreferencesUseCase = saveOnboardingPreferencesUseCase,
       _completeOnboardingUseCase = completeOnboardingUseCase,
       super(OnboardingState());

  /// Load onboarding preferences and progress
  Future<void> loadOnboardingData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final preferences = await _getOnboardingPreferencesUseCase.execute();
      // TODO: Load progress when progress API is implemented
      // final progress = await _getOnboardingProgressUseCase.execute();

      state = state.copyWith(
        preferences: preferences,
        // progress: progress,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Save onboarding preferences
  Future<void> savePreferences(OnboardingPreferences preferences) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      final savedPreferences = await _saveOnboardingPreferencesUseCase.execute(preferences);
      state = state.copyWith(
        preferences: savedPreferences,
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
    }
  }

  /// Update relationship goal
  Future<void> updateRelationshipGoal(String goal) async {
    final updatedPreferences = state.preferences.copyWith(relationshipGoal: goal);
    await savePreferences(updatedPreferences);
  }

  /// Update interests
  Future<void> updateInterests(List<String> interests) async {
    final updatedPreferences = state.preferences.copyWith(interests: interests);
    await savePreferences(updatedPreferences);
  }

  /// Update preferred gender
  Future<void> updatePreferredGender(String gender) async {
    final updatedPreferences = state.preferences.copyWith(preferredGender: gender);
    await savePreferences(updatedPreferences);
  }

  /// Update age range
  Future<void> updateAgeRange(int minAge, int maxAge) async {
    final updatedPreferences = state.preferences.copyWith(
      ageRangeMin: minAge,
      ageRangeMax: maxAge,
    );
    await savePreferences(updatedPreferences);
  }

  /// Update max distance
  Future<void> updateMaxDistance(double distance) async {
    final updatedPreferences = state.preferences.copyWith(maxDistance: distance);
    await savePreferences(updatedPreferences);
  }

  /// Update show me on app preference
  Future<void> updateShowMeOnApp(bool show) async {
    final updatedPreferences = state.preferences.copyWith(showMeOnApp: show);
    await savePreferences(updatedPreferences);
  }

  /// Update notifications preference
  Future<void> updateReceiveNotifications(bool receive) async {
    final updatedPreferences = state.preferences.copyWith(receiveNotifications: receive);
    await savePreferences(updatedPreferences);
  }

  /// Complete onboarding
  Future<bool> completeOnboarding({bool skipRemainingSteps = false}) async {
    state = state.copyWith(isCompleting: true, error: null);

    try {
      final request = CompleteOnboardingRequest(
        preferences: state.preferences,
        skipRemainingSteps: skipRemainingSteps,
      );

      final success = await _completeOnboardingUseCase.execute(request);

      if (success) {
        state = state.copyWith(
          isCompleting: false,
          isCompleted: true,
        );
      } else {
        state = state.copyWith(
          isCompleting: false,
          error: 'Failed to complete onboarding',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isCompleting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Skip onboarding
  Future<bool> skipOnboarding() async {
    try {
      // TODO: Implement skip onboarding
      // final success = await _skipOnboardingUseCase.execute();
      state = state.copyWith(isCompleted: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Go to next step
  void nextStep() {
    if (state.currentStep < state.totalSteps) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Go to previous step
  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 1 && step <= state.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Check if current step is valid
  bool get isCurrentStepValid {
    switch (state.currentStep) {
      case 1:
        return state.preferences.relationshipGoal != null;
      case 2:
        return state.preferences.interests != null && state.preferences.interests!.isNotEmpty;
      case 3:
        return state.preferences.preferredGender != null;
      case 4:
        return state.preferences.ageRangeMin != null && state.preferences.ageRangeMax != null;
      case 5:
        return state.preferences.maxDistance != null;
      default:
        return true;
    }
  }

  /// Get completion percentage
  double get completionPercentage {
    return state.preferences.completionPercentage;
  }

  /// Check if onboarding can be completed
  bool get canCompleteOnboarding {
    return state.preferences.isComplete;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset onboarding
  void reset() {
    state = OnboardingState();
  }
}

// Use case providers
final getOnboardingPreferencesUseCaseProvider = Provider<GetOnboardingPreferencesUseCase>((ref) {
  throw UnimplementedError('GetOnboardingPreferencesUseCase must be overridden in the provider scope');
});

final saveOnboardingPreferencesUseCaseProvider = Provider<SaveOnboardingPreferencesUseCase>((ref) {
  throw UnimplementedError('SaveOnboardingPreferencesUseCase must be overridden in the provider scope');
});

final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>((ref) {
  throw UnimplementedError('CompleteOnboardingUseCase must be overridden in the provider scope');
});
