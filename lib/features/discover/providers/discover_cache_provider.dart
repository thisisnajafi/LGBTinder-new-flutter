// Discover page cache-first: cache is single source of truth.
// Render from cache immediately; background fetch merges by id; swipe updates cache then syncs to server.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/models/api_error.dart';
import '../../../shared/services/cache_service.dart';
import '../../matching/data/models/match.dart' as match_models;
import '../../matching/data/services/likes_service.dart';
import '../../matching/providers/likes_providers.dart';
import '../../payments/data/services/plan_limits_service.dart';
import '../data/models/cached_discover_item.dart';
import '../data/models/discovery_profile.dart';
import '../data/services/discovery_service.dart';
import 'discovery_providers.dart';

/// State for the discover feed cache. UI renders only from [stack].
class DiscoverCacheState {
  final List<CachedDiscoverItem> items;
  final bool initialLoadComplete;
  final int nextPage;

  const DiscoverCacheState({
    this.items = const [],
    this.initialLoadComplete = false,
    this.nextPage = 1,
  });

  /// Profiles still in the stack (interaction_state == none). Order preserved.
  List<DiscoveryProfile> get stack =>
      items.where((e) => e.interactionState == DiscoverInteractionState.none).map((e) => e.profile).toList();

  int get stackLength => items.where((e) => e.interactionState == DiscoverInteractionState.none).length;
}

/// Buffer threshold: fetch more when stack drops below this.
const int kDiscoverStackBufferThreshold = 5;

final discoverCacheProvider =
    StateNotifierProvider<DiscoverCacheNotifier, DiscoverCacheState>((ref) {
  return DiscoverCacheNotifier(
    ref.read(discoveryServiceProvider),
    ref.read(likesServiceProvider),
    ref.read(planLimitsServiceProvider),
    ref.read(cacheServiceProvider),
  );
});

class DiscoverCacheNotifier extends StateNotifier<DiscoverCacheState> {
  DiscoverCacheNotifier(
    this._discoveryService,
    this._likesService,
    this._planLimitsService,
    this._cacheService,
  ) : super(const DiscoverCacheState()) {
    _init();
  }

  final DiscoveryService _discoveryService;
  final LikesService _likesService;
  final PlanLimitsService _planLimitsService;
  final CacheService _cacheService;

  static const int _pageSize = 20;
  bool _isRefreshing = false;
  bool _isFetchingMore = false;
  /// Throttle fetch-more: do not call again within this duration (avoids request storm on rebuild).
  static const Duration _fetchMoreThrottle = Duration(seconds: 15);
  DateTime? _lastFetchMoreAt;

  void _init() {
    Future.microtask(loadFromCache);
  }

  /// Load feed from cache only. No network. UI can render immediately.
  Future<void> loadFromCache() async {
    try {
      final cached = await _cacheService.getCached<Map<String, dynamic>>(
        CacheKeys.discoverFeed,
        (json) => Map<String, dynamic>.from(json),
        customExpiry: CacheDuration.matches,
      );
      final raw = cached?['list'];
      if (raw is List && raw.isNotEmpty) {
        final list = <CachedDiscoverItem>[];
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            try {
              list.add(CachedDiscoverItem.fromJson(e));
            } catch (_) {}
          }
        }
        if (list.isNotEmpty) {
          state = DiscoverCacheState(
            items: list,
            initialLoadComplete: state.initialLoadComplete,
            nextPage: state.nextPage,
          );
        }
      }
    } catch (_) {}
  }

  /// Merge [profiles] into state by id: existing ids keep state, new ids get none. Then persist.
  void _mergeAndPersist(List<DiscoveryProfile> profiles, {int? nextPage}) {
    final existingIds = state.items.map((e) => e.id).toSet();
    final newItems = profiles
        .where((p) => !existingIds.contains(p.id))
        .map((p) => CachedDiscoverItem(profile: p, interactionState: DiscoverInteractionState.none))
        .toList();
    if (newItems.isEmpty && nextPage == null) return;
    final merged = [...state.items];
    for (final item in newItems) {
      if (!existingIds.contains(item.id)) {
        merged.add(item);
        existingIds.add(item.id);
      }
    }
    state = DiscoverCacheState(
      items: merged,
      initialLoadComplete: true,
      nextPage: nextPage ?? state.nextPage,
    );
    _persist(merged);
  }

  Future<void> _persist(List<CachedDiscoverItem> list) async {
    final raw = list.map((e) => e.toJson()).toList();
    await _cacheService.cacheData(
      CacheKeys.discoverFeed,
      <String, dynamic>{'list': raw},
      duration: CacheDuration.matches,
    );
  }

  /// Persist current state items (e.g. after swipe).
  Future<void> _persistState() async {
    await _persist(state.items);
  }

  /// Background refresh: fetch page 1, merge by id, do not clear existing items.
  Future<void> _refresh({Map<String, dynamic>? filters}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final profiles = await _discoveryService.fetchNearbySuggestionsFromApi(
        page: 1,
        limit: _pageSize,
        filters: filters,
      );
      _mergeAndPersist(profiles, nextPage: 2);
    } catch (_) {
      state = DiscoverCacheState(
        items: state.items,
        initialLoadComplete: true,
        nextPage: state.nextPage,
      );
    } finally {
      _isRefreshing = false;
    }
  }

  /// Call when Discover page is shown: render from cache, then refresh in background.
  Future<void> refresh({Map<String, dynamic>? filters}) async {
    await loadFromCache();
    unawaited(_refresh(filters: filters));
  }

  /// Fetch more and merge when stack drops below threshold. Throttled to avoid repeated calls.
  Future<void> fetchMoreIfNeeded({
    required int threshold,
    Map<String, dynamic>? filters,
  }) async {
    if (state.stackLength >= threshold || _isFetchingMore) return;
    if (_lastFetchMoreAt != null &&
        DateTime.now().difference(_lastFetchMoreAt!) < _fetchMoreThrottle) {
      return;
    }
    _isFetchingMore = true;
    _lastFetchMoreAt = DateTime.now();
    try {
      final page = state.nextPage;
      final profiles = await _discoveryService.fetchNearbySuggestionsFromApi(
        page: page,
        limit: _pageSize,
        filters: filters,
      );
      _mergeAndPersist(profiles, nextPage: page + 1);
    } catch (_) {}
    finally {
      _isFetchingMore = false;
    }
  }

  /// Record swipe optimistically: update cache and state, then sync to server in background.
  /// [onMatch] called when like/superlike returns a match. [onLimitError] when 429/limit.
  /// [onTheyLikedYou] called when dislike returns they_liked_you.
  void recordSwipe(
    int userId,
    String action, {
    void Function(match_models.Match?)? onMatch,
    void Function(dynamic)? onLimitError,
    void Function()? onTheyLikedYou,
  }) {
    final idx = state.items.indexWhere((e) => e.profile.id == userId);
    if (idx < 0) return;
    final item = state.items[idx];
    if (item.interactionState != DiscoverInteractionState.none) return;

    DiscoverInteractionState newState;
    switch (action) {
      case 'like':
        newState = DiscoverInteractionState.liked;
        break;
      case 'dislike':
        newState = DiscoverInteractionState.disliked;
        break;
      case 'superlike':
        newState = DiscoverInteractionState.superLiked;
        break;
      default:
        return;
    }

    final updated = item.copyWith(
      interactionState: newState,
      syncStatus: DiscoverSyncStatus.pending,
    );
    final newList = List<CachedDiscoverItem>.from(state.items)..[idx] = updated;
    state = DiscoverCacheState(
      items: newList,
      initialLoadComplete: state.initialLoadComplete,
      nextPage: state.nextPage,
    );
    unawaited(_persistState());

    unawaited(_syncSwipeToServer(userId, action, updated, newList, onMatch, onLimitError, onTheyLikedYou));
  }

  Future<void> _syncSwipeToServer(
    int userId,
    String action,
    CachedDiscoverItem updated,
    List<CachedDiscoverItem> currentList,
    void Function(match_models.Match?)? onMatch,
    void Function(dynamic)? onLimitError,
    void Function()? onTheyLikedYou,
  ) async {
    try {
      switch (action) {
        case 'like': {
          final response = await _likesService.likeUser(userId);
          _planLimitsService.incrementUsage('swipes');
          _planLimitsService.incrementUsage('likes');
          _markSynced(userId);
          if (response.isMatch && onMatch != null) {
            onMatch(response.match);
          }
          break;
        }
        case 'dislike': {
          final response = await _likesService.dislikeUser(userId);
          _planLimitsService.incrementUsage('swipes');
          _markSynced(userId);
          if (response.theyLikedYou && onTheyLikedYou != null) {
            onTheyLikedYou();
          }
          break;
        }
        case 'superlike': {
          final response = await _likesService.superlikeUser(userId);
          _planLimitsService.incrementUsage('swipes');
          _planLimitsService.incrementUsage('superlikes');
          _markSynced(userId);
          if (response.isMatch && onMatch != null) {
            onMatch(response.match);
          }
          break;
        }
      }
    } catch (e) {
      final err = e;
      final isLimit = _isLimitError(err);
      if (isLimit && onLimitError != null) {
        onLimitError(err);
      }
      _markSyncFailed(userId);
    }
  }

  bool _isLimitError(dynamic e) {
    if (e is ApiError) {
      final code = e.responseData?['error_code'] as String?;
      return code == 'DAILY_VIEW_LIMIT_REACHED' ||
          code == 'DAILY_LIMIT_REACHED' ||
          code == 'DAILY_LIKE_LIMIT_REACHED' ||
          e.code == 429;
    }
    return false;
  }

  void _markSynced(int userId) {
    final idx = state.items.indexWhere((e) => e.profile.id == userId);
    if (idx < 0) return;
    final item = state.items[idx];
    final newList = List<CachedDiscoverItem>.from(state.items)
      ..[idx] = item.copyWith(syncStatus: DiscoverSyncStatus.synced);
    state = DiscoverCacheState(
      items: newList,
      initialLoadComplete: state.initialLoadComplete,
      nextPage: state.nextPage,
    );
    unawaited(_persistState());
  }

  void _markSyncFailed(int userId) {
    final idx = state.items.indexWhere((e) => e.profile.id == userId);
    if (idx < 0) return;
    final item = state.items[idx];
    final newList = List<CachedDiscoverItem>.from(state.items)
      ..[idx] = item.copyWith(syncStatus: DiscoverSyncStatus.failed);
    state = DiscoverCacheState(
      items: newList,
      initialLoadComplete: state.initialLoadComplete,
      nextPage: state.nextPage,
    );
    unawaited(_persistState());
  }
}
