import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_analytics.dart';
import '../data/repositories/analytics_repository.dart';
import '../domain/use_cases/get_analytics_use_case.dart';
import '../domain/use_cases/track_activity_use_case.dart';

/// Analytics provider - manages analytics state and functionality
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final getAnalyticsUseCase = ref.watch(getAnalyticsUseCaseProvider);
  final trackActivityUseCase = ref.watch(trackActivityUseCaseProvider);

  return AnalyticsNotifier(
    getAnalyticsUseCase: getAnalyticsUseCase,
    trackActivityUseCase: trackActivityUseCase,
  );
});

/// Analytics state
class AnalyticsState {
  final UserAnalytics? analytics;
  final bool isLoading;
  final bool isTrackingActivity;
  final String? error;
  final int? selectedPeriodDays;

  AnalyticsState({
    this.analytics,
    this.isLoading = false,
    this.isTrackingActivity = false,
    this.error,
    this.selectedPeriodDays = 30,
  });

  AnalyticsState copyWith({
    UserAnalytics? analytics,
    bool? isLoading,
    bool? isTrackingActivity,
    String? error,
    int? selectedPeriodDays,
  }) {
    return AnalyticsState(
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      isTrackingActivity: isTrackingActivity ?? this.isTrackingActivity,
      error: error ?? this.error,
      selectedPeriodDays: selectedPeriodDays ?? this.selectedPeriodDays,
    );
  }
}

/// Analytics notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final GetAnalyticsUseCase _getAnalyticsUseCase;
  final TrackActivityUseCase _trackActivityUseCase;

  AnalyticsNotifier({
    required GetAnalyticsUseCase getAnalyticsUseCase,
    required TrackActivityUseCase trackActivityUseCase,
  }) : _getAnalyticsUseCase = getAnalyticsUseCase,
       _trackActivityUseCase = trackActivityUseCase,
       super(AnalyticsState());

  /// Load user analytics
  Future<void> loadAnalytics({int days = 30}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedPeriodDays: days,
    );

    try {
      final analytics = await _getAnalyticsUseCase.execute(days: days);
      state = state.copyWith(
        analytics: analytics,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Track user activity
  Future<void> trackActivity({
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isTrackingActivity: true);

    try {
      await _trackActivityUseCase.execute(
        action: action,
        metadata: metadata ?? {},
      );
      state = state.copyWith(isTrackingActivity: false);

      // Reload analytics to reflect the new activity
      if (state.selectedPeriodDays != null) {
        await loadAnalytics(days: state.selectedPeriodDays!);
      }
    } catch (e) {
      state = state.copyWith(
        isTrackingActivity: false,
        error: e.toString(),
      );
    }
  }

  /// Change analytics period
  void changePeriod(int days) {
    state = state.copyWith(selectedPeriodDays: days);
    loadAnalytics(days: days);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Get Analytics Use Case Provider
final getAnalyticsUseCaseProvider = Provider<GetAnalyticsUseCase>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  return GetAnalyticsUseCase(repository);
});

/// Track Activity Use Case Provider
final trackActivityUseCaseProvider = Provider<TrackActivityUseCase>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  return TrackActivityUseCase(repository);
});
