import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/discovery_profile.dart';
import '../data/models/discovery_filters.dart';
import '../domain/use_cases/get_discovery_profiles_use_case.dart';
import '../domain/use_cases/get_nearby_suggestions_use_case.dart';
import '../domain/use_cases/apply_filters_use_case.dart';

/// Discovery provider - manages discovery state and operations
final discoveryProvider = StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final getDiscoveryProfilesUseCase = ref.watch(getDiscoveryProfilesUseCaseProvider);
  final getNearbySuggestionsUseCase = ref.watch(getNearbySuggestionsUseCaseProvider);
  final applyFiltersUseCase = ref.watch(applyFiltersUseCaseProvider);

  return DiscoveryNotifier(
    getDiscoveryProfilesUseCase: getDiscoveryProfilesUseCase,
    getNearbySuggestionsUseCase: getNearbySuggestionsUseCase,
    applyFiltersUseCase: applyFiltersUseCase,
  );
});

/// Discovery state
class DiscoveryState {
  final List<DiscoveryProfile> profiles;
  final DiscoveryFilters filters;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMoreProfiles;
  final int currentIndex;

  DiscoveryState({
    this.profiles = const [],
    DiscoveryFilters? filters,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMoreProfiles = true,
    this.currentIndex = 0,
  }) : filters = filters ?? DiscoveryFilters();

  DiscoveryState copyWith({
    List<DiscoveryProfile>? profiles,
    DiscoveryFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMoreProfiles,
    int? currentIndex,
  }) {
    return DiscoveryState(
      profiles: profiles ?? this.profiles,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      hasMoreProfiles: hasMoreProfiles ?? this.hasMoreProfiles,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

/// Discovery notifier
class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final GetDiscoveryProfilesUseCase _getDiscoveryProfilesUseCase;
  final GetNearbySuggestionsUseCase _getNearbySuggestionsUseCase;
  final ApplyFiltersUseCase _applyFiltersUseCase;

  DiscoveryNotifier({
    required GetDiscoveryProfilesUseCase getDiscoveryProfilesUseCase,
    required GetNearbySuggestionsUseCase getNearbySuggestionsUseCase,
    required ApplyFiltersUseCase applyFiltersUseCase,
  }) : _getDiscoveryProfilesUseCase = getDiscoveryProfilesUseCase,
       _getNearbySuggestionsUseCase = getNearbySuggestionsUseCase,
       _applyFiltersUseCase = applyFiltersUseCase,
       super(DiscoveryState());

  /// Load initial discovery profiles
  Future<void> loadProfiles() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profiles = await _getDiscoveryProfilesUseCase.execute(
        limit: 20,
        filters: state.filters.isEmpty ? null : state.filters,
      );

      state = state.copyWith(
        profiles: profiles,
        isLoading: false,
        hasMoreProfiles: profiles.length >= 20,
        currentIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more profiles for infinite scroll
  Future<void> loadMoreProfiles() async {
    if (!state.hasMoreProfiles || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final profiles = await _getNearbySuggestionsUseCase.execute(
        limit: 10,
        filters: state.filters.isEmpty ? null : state.filters,
      );

      if (profiles.isEmpty) {
        state = state.copyWith(
          isLoadingMore: false,
          hasMoreProfiles: false,
        );
      } else {
        state = state.copyWith(
          profiles: [...state.profiles, ...profiles],
          isLoadingMore: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Apply filters and reload profiles
  Future<void> applyFilters(DiscoveryFilters filters) async {
    state = state.copyWith(
      filters: filters,
      isLoading: true,
      error: null,
      profiles: [],
      currentIndex: 0,
    );

    try {
      final profiles = await _applyFiltersUseCase.execute(filters);

      state = state.copyWith(
        profiles: profiles,
        isLoading: false,
        hasMoreProfiles: profiles.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update filters (without reloading)
  void updateFilters(DiscoveryFilters filters) {
    state = state.copyWith(filters: filters);
  }

  /// Like current profile
  Future<void> likeCurrentProfile() async {
    final currentProfile = _getCurrentProfile();
    if (currentProfile != null) {
      // TODO: Implement like action
      _moveToNextProfile();
    }
  }

  /// Dislike current profile
  Future<void> dislikeCurrentProfile() async {
    final currentProfile = _getCurrentProfile();
    if (currentProfile != null) {
      // TODO: Implement dislike action
      _moveToNextProfile();
    }
  }

  /// Superlike current profile
  Future<void> superlikeCurrentProfile() async {
    final currentProfile = _getCurrentProfile();
    if (currentProfile != null) {
      // TODO: Implement superlike action
      _moveToNextProfile();
    }
  }

  /// Skip to next profile
  void skipCurrentProfile() {
    _moveToNextProfile();
  }

  /// Rewind to previous profile (if available)
  void rewindProfile() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Get current profile being viewed
  DiscoveryProfile? getCurrentProfile() => _getCurrentProfile();

  /// Check if there are more profiles
  bool get hasMoreProfiles => state.currentIndex < state.profiles.length - 1;

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset discovery state
  void reset() {
    state = DiscoveryState();
  }

  DiscoveryProfile? _getCurrentProfile() {
    if (state.profiles.isEmpty || state.currentIndex >= state.profiles.length) {
      return null;
    }
    return state.profiles[state.currentIndex];
  }

  void _moveToNextProfile() {
    if (state.currentIndex < state.profiles.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      // Load more profiles if available
      loadMoreProfiles();
    }
  }
}

// Use case providers
final getDiscoveryProfilesUseCaseProvider = Provider<GetDiscoveryProfilesUseCase>((ref) {
  throw UnimplementedError('GetDiscoveryProfilesUseCase must be overridden in the provider scope');
});

final getNearbySuggestionsUseCaseProvider = Provider<GetNearbySuggestionsUseCase>((ref) {
  throw UnimplementedError('GetNearbySuggestionsUseCase must be overridden in the provider scope');
});

final applyFiltersUseCaseProvider = Provider<ApplyFiltersUseCase>((ref) {
  throw UnimplementedError('ApplyFiltersUseCase must be overridden in the provider scope');
});
