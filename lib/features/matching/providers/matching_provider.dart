import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/like.dart';
import '../data/models/match.dart';
import '../data/models/superlike.dart';
import '../data/models/compatibility_score.dart';
import '../domain/use_cases/like_profile_use_case.dart';
import '../domain/use_cases/superlike_profile_use_case.dart';
import '../domain/use_cases/get_pending_likes_use_case.dart';
import '../domain/use_cases/get_superlike_history_use_case.dart';
import '../domain/use_cases/get_matches_use_case.dart';
import '../domain/use_cases/get_compatibility_score_use_case.dart';

/// Matching provider - manages matching state and operations
final matchingProvider = StateNotifierProvider<MatchingNotifier, MatchingState>((ref) {
  final likeProfileUseCase = ref.watch(likeProfileUseCaseProvider);
  final superlikeProfileUseCase = ref.watch(superlikeProfileUseCaseProvider);
  final getMatchesUseCase = ref.watch(getMatchesUseCaseProvider);
  final getCompatibilityScoreUseCase = ref.watch(getCompatibilityScoreUseCaseProvider);
  final getPendingLikesUseCase = ref.watch(getPendingLikesUseCaseProvider);
  final getSuperlikeHistoryUseCase = ref.watch(getSuperlikeHistoryUseCaseProvider);

  return MatchingNotifier(
    likeProfileUseCase: likeProfileUseCase,
    superlikeProfileUseCase: superlikeProfileUseCase,
    getMatchesUseCase: getMatchesUseCase,
    getCompatibilityScoreUseCase: getCompatibilityScoreUseCase,
    getPendingLikesUseCase: getPendingLikesUseCase,
    getSuperlikeHistoryUseCase: getSuperlikeHistoryUseCase,
  );
});

/// Matching state
class MatchingState {
  final List<Match> matches;
  final List<Like> pendingLikes;
  final List<Superlike> superlikeHistory;
  final CompatibilityScore? compatibilityScore;
  final bool isLoading;
  final bool isLiking;
  final bool isSuperliking;
  final String? error;
  final bool hasNewMatches;
  final int unreadMatchCount;

  MatchingState({
    this.matches = const [],
    this.pendingLikes = const [],
    this.superlikeHistory = const [],
    this.compatibilityScore,
    this.isLoading = false,
    this.isLiking = false,
    this.isSuperliking = false,
    this.error,
    this.hasNewMatches = false,
    this.unreadMatchCount = 0,
  });

  MatchingState copyWith({
    List<Match>? matches,
    List<Like>? pendingLikes,
    List<Superlike>? superlikeHistory,
    CompatibilityScore? compatibilityScore,
    bool? isLoading,
    bool? isLiking,
    bool? isSuperliking,
    String? error,
    bool? hasNewMatches,
    int? unreadMatchCount,
  }) {
    return MatchingState(
      matches: matches ?? this.matches,
      pendingLikes: pendingLikes ?? this.pendingLikes,
      superlikeHistory: superlikeHistory ?? this.superlikeHistory,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      isLoading: isLoading ?? this.isLoading,
      isLiking: isLiking ?? this.isLiking,
      isSuperliking: isSuperliking ?? this.isSuperliking,
      error: error ?? this.error,
      hasNewMatches: hasNewMatches ?? this.hasNewMatches,
      unreadMatchCount: unreadMatchCount ?? this.unreadMatchCount,
    );
  }
}

/// Matching notifier
class MatchingNotifier extends StateNotifier<MatchingState> {
  final LikeProfileUseCase _likeProfileUseCase;
  final SuperlikeProfileUseCase _superlikeProfileUseCase;
  final GetMatchesUseCase _getMatchesUseCase;
  final GetCompatibilityScoreUseCase _getCompatibilityScoreUseCase;
  final GetPendingLikesUseCase _getPendingLikesUseCase;
  final GetSuperlikeHistoryUseCase _getSuperlikeHistoryUseCase;

  MatchingNotifier({
    required LikeProfileUseCase likeProfileUseCase,
    required SuperlikeProfileUseCase superlikeProfileUseCase,
    required GetMatchesUseCase getMatchesUseCase,
    required GetCompatibilityScoreUseCase getCompatibilityScoreUseCase,
    required GetPendingLikesUseCase getPendingLikesUseCase,
    required GetSuperlikeHistoryUseCase getSuperlikeHistoryUseCase,
  }) : _likeProfileUseCase = likeProfileUseCase,
       _superlikeProfileUseCase = superlikeProfileUseCase,
       _getMatchesUseCase = getMatchesUseCase,
       _getCompatibilityScoreUseCase = getCompatibilityScoreUseCase,
       _getPendingLikesUseCase = getPendingLikesUseCase,
       _getSuperlikeHistoryUseCase = getSuperlikeHistoryUseCase,
       super(MatchingState());

  /// Load all matches
  Future<void> loadMatches() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final matches = await _getMatchesUseCase.execute();
      final unreadCount = matches.where((match) => !(match.isRead ?? true)).length;

      state = state.copyWith(
        matches: matches,
        isLoading: false,
        unreadMatchCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load pending likes (likes received)
  Future<void> loadPendingLikes() async {
    try {
      final pendingLikes = await _getPendingLikesUseCase.execute();
      state = state.copyWith(pendingLikes: pendingLikes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load superlike history
  Future<void> loadSuperlikeHistory() async {
    try {
      final superlikeHistory = await _getSuperlikeHistoryUseCase.execute();
      state = state.copyWith(superlikeHistory: superlikeHistory);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Like a profile
  Future<LikeResponse?> likeProfile(int profileId) async {
    state = state.copyWith(isLiking: true, error: null);

    try {
      final response = await _likeProfileUseCase.execute(profileId);

      // If it's a match, add it to matches list
      if (response.isMatch && response.match != null) {
        final updatedMatches = [response.match!, ...state.matches];
        state = state.copyWith(
          matches: updatedMatches,
          isLiking: false,
          hasNewMatches: true,
          unreadMatchCount: state.unreadMatchCount + 1,
        );
      } else {
        state = state.copyWith(isLiking: false);
      }

      return response;
    } catch (e) {
      state = state.copyWith(
        isLiking: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Superlike a profile
  Future<SuperlikeResponse?> superlikeProfile(int profileId) async {
    state = state.copyWith(isSuperliking: true, error: null);

    try {
      final response = await _superlikeProfileUseCase.execute(profileId);

      // If it's a match, add it to matches list
      if (response.isMatch && response.match != null) {
        final updatedMatches = [response.match!, ...state.matches];
        state = state.copyWith(
          matches: updatedMatches,
          isSuperliking: false,
          hasNewMatches: true,
          unreadMatchCount: state.unreadMatchCount + 1,
        );
      } else {
        state = state.copyWith(isSuperliking: false);
      }

      return response;
    } catch (e) {
      state = state.copyWith(
        isSuperliking: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Get compatibility score for a user
  Future<void> loadCompatibilityScore(int targetUserId) async {
    try {
      final score = await _getCompatibilityScoreUseCase.execute(targetUserId);
      state = state.copyWith(compatibilityScore: score);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark match as read
  void markMatchAsRead(int matchId) {
    final updatedMatches = state.matches.map((match) {
      if (match.id == matchId) {
        return Match(
          id: match.id,
          userId: match.userId,
          firstName: match.firstName,
          lastName: match.lastName,
          profileBio: match.profileBio,
          primaryImageUrl: match.primaryImageUrl,
          imageUrls: match.imageUrls,
          matchedAt: match.matchedAt,
          isRead: true,
          lastMessage: match.lastMessage,
          lastMessageAt: match.lastMessageAt,
          unreadCount: 0,
        );
      }
      return match;
    }).toList();

    final newUnreadCount = state.unreadMatchCount > 0 ? state.unreadMatchCount - 1 : 0;

    state = state.copyWith(
      matches: updatedMatches,
      unreadMatchCount: newUnreadCount,
    );
  }

  /// Clear new matches flag
  void clearNewMatchesFlag() {
    state = state.copyWith(hasNewMatches: false);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset matching state
  void reset() {
    state = MatchingState();
  }
}

// Use case providers
final likeProfileUseCaseProvider = Provider<LikeProfileUseCase>((ref) {
  throw UnimplementedError('LikeProfileUseCase must be overridden in the provider scope');
});

final superlikeProfileUseCaseProvider = Provider<SuperlikeProfileUseCase>((ref) {
  throw UnimplementedError('SuperlikeProfileUseCase must be overridden in the provider scope');
});

final getMatchesUseCaseProvider = Provider<GetMatchesUseCase>((ref) {
  throw UnimplementedError('GetMatchesUseCase must be overridden in the provider scope');
});

final getCompatibilityScoreUseCaseProvider = Provider<GetCompatibilityScoreUseCase>((ref) {
  throw UnimplementedError('GetCompatibilityScoreUseCase must be overridden in the provider scope');
});

final getPendingLikesUseCaseProvider = Provider<GetPendingLikesUseCase>((ref) {
  throw UnimplementedError('GetPendingLikesUseCase must be overridden in the provider scope');
});

final getSuperlikeHistoryUseCaseProvider = Provider<GetSuperlikeHistoryUseCase>((ref) {
  throw UnimplementedError('GetSuperlikeHistoryUseCase must be overridden in the provider scope');
});
