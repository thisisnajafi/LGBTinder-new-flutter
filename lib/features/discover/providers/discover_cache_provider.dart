// Discover page cache-first: cache is single source of truth.
// Render from cache immediately; background fetch merges by id; swipe updates cache then syncs to server.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/cache/cache_invalidator.dart';
import '../../../core/cache/session_cache_providers.dart';
import '../../../core/cache/session_data_cache_service.dart';
import '../../payments/providers/payment_providers.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/models/api_error.dart';
import '../../../shared/services/cache_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/data/models/message.dart';
import '../../chat/providers/chat_list_preview_provider.dart';
import '../../chat/providers/chat_providers.dart';
import '../../matching/data/models/like.dart';
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

/// Encodes discover feed JSON off the UI thread (used by [compute]).
String encodeDiscoverFeedForCache(List<Map<String, dynamic>> raw) {
  return jsonEncode(<String, dynamic>{'list': raw});
}

final discoverCacheProvider =
    StateNotifierProvider<DiscoverCacheNotifier, DiscoverCacheState>((ref) {
  return DiscoverCacheNotifier(
    ref,
    ref.read(discoveryServiceProvider),
    ref.read(likesServiceProvider),
    ref.read(planLimitsServiceProvider),
    ref.read(cacheServiceProvider),
    ref.read(cacheInvalidatorProvider),
    ref.read(sessionDataCacheServiceProvider),
  );
});

class DiscoverCacheNotifier extends StateNotifier<DiscoverCacheState> {
  DiscoverCacheNotifier(
    this._ref,
    this._discoveryService,
    this._likesService,
    this._planLimitsService,
    this._cacheService,
    this._cacheInvalidator,
    this._sessionCache,
  ) : super(const DiscoverCacheState()) {
    _init();
  }

  final Ref _ref;
  final DiscoveryService _discoveryService;
  final LikesService _likesService;
  final PlanLimitsService _planLimitsService;
  final CacheService _cacheService;
  final CacheInvalidator _cacheInvalidator;
  final SessionDataCacheService _sessionCache;

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
            } catch (e, stack) {
              AppLogger.warning(
                'Failed to parse cached discover item',
                tag: 'DiscoverCache',
                error: e,
              );
              AppLogger.debug('Parse stack: $stack', tag: 'DiscoverCache');
            }
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
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load discover cache',
        tag: 'DiscoverCache',
        error: e,
        stackTrace: stack,
      );
    }
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
    final encoded = await compute(encodeDiscoverFeedForCache, raw);
    await _cacheService.cacheEncodedJson(
      CacheKeys.discoverFeed,
      encoded,
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
    } catch (e, stack) {
      AppLogger.error(
        'Discover feed refresh failed',
        tag: 'DiscoverCache',
        error: e,
        stackTrace: stack,
      );
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
    } catch (e, stack) {
      AppLogger.error(
        'Discover fetch-more failed',
        tag: 'DiscoverCache',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _isFetchingMore = false;
    }
  }

  /// Record swipe optimistically: update cache and state, then sync to server in background.
  /// [onMatch] called when like/superlike returns a match. [onLimitError] when 429/limit.
  /// [onTheyLikedYou] called when dislike returns they_liked_you.
  /// [onLostMatch] called when dislike removes an existing mutual match.
  void recordSwipe(
    int userId,
    String action, {
    String? superlikeMessage,
    void Function(match_models.Match?)? onMatch,
    void Function(dynamic)? onLimitError,
    void Function()? onTheyLikedYou,
    void Function()? onLostMatch,
    void Function()? onSuperlikeSent,
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
        AppLogger.debug(
          'recordSwipe optimistic userId=$userId hasMessage=${superlikeMessage?.isNotEmpty == true}',
          tag: 'DiscoverySuperlike',
        );
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

    unawaited(
      _syncSwipeToServer(
        userId,
        action,
        superlikeMessage,
        updated,
        newList,
        onMatch,
        onLimitError,
        onTheyLikedYou,
        onLostMatch,
        onSuperlikeSent,
      ),
    );
  }

  Future<void> _syncSwipeToServer(
    int userId,
    String action,
    String? superlikeMessage,
    CachedDiscoverItem updated,
    List<CachedDiscoverItem> currentList,
    void Function(match_models.Match?)? onMatch,
    void Function(dynamic)? onLimitError,
    void Function()? onTheyLikedYou,
    void Function()? onLostMatch,
    void Function()? onSuperlikeSent,
  ) async {
    try {
      switch (action) {
        case 'like': {
          final response = await _likesService.likeUser(userId);
          _planLimitsService.incrementUsage('swipes');
          _planLimitsService.incrementUsage('likes');
          _markSynced(userId);
          if (response.isMatch) {
            unawaited(_cacheInvalidator.purgeMatchList());
            if (onMatch != null) onMatch(response.match);
          }
          break;
        }
        case 'dislike': {
          final response = await _likesService.dislikeUser(userId);
          _planLimitsService.incrementUsage('swipes');
          _markSynced(userId);
          if (response.wasMatch) {
            unawaited(_cacheInvalidator.purgeMatchList());
            onLostMatch?.call();
          } else if (response.theyLikedYou) {
            onTheyLikedYou?.call();
          }
          break;
        }
        case 'superlike': {
          AppLogger.debug(
            'sync superlike API start userId=$userId messageLen=${superlikeMessage?.length ?? 0}',
            tag: 'DiscoverySuperlike',
          );
          final response =
              await _likesService.superlikeUser(userId, message: superlikeMessage);
          AppLogger.debug(
            'sync superlike API ok userId=$userId remaining=${response.superlikesRemaining} isMatch=${response.isMatch}',
            tag: 'DiscoverySuperlike',
          );
          _planLimitsService.incrementUsage('swipes');
          _markSynced(userId);
          if (response.subscription != null &&
              response.superlikesRemaining != null) {
            await _sessionCache.applySuperlikeSendResponse(
              superlikesRemaining: response.superlikesRemaining!,
              subscriptionJson: response.subscription!.toJson(),
            );
            _ref
                .read(superlikesRemainingProvider.notifier)
                .setCount(response.superlikesRemaining!);
            _ref
                .read(cachedUserTierProvider.notifier)
                .setTier(response.subscription!.tier);
            _planLimitsService.applySuperlikesRemaining(
              response.superlikesRemaining!,
            );
          } else if (response.superlikesRemaining != null) {
            await _sessionCache.setSuperlikesRemaining(
              response.superlikesRemaining!,
            );
            _ref
                .read(superlikesRemainingProvider.notifier)
                .setCount(response.superlikesRemaining!);
            _planLimitsService.applySuperlikesRemaining(
              response.superlikesRemaining!,
            );
          } else {
            _planLimitsService.incrementUsage('superlikes');
          }
          _deferPlanLimitsRefresh();
          _deferSubscriptionRefresh();
          if (response.isMatch) {
            unawaited(_cacheInvalidator.purgeMatchList());
            if (onMatch != null) onMatch(response.match);
          } else {
            await _upsertChatListAfterSuperlike(
              userId: userId,
              currentList: currentList,
              introMessage: superlikeMessage,
              response: response,
            );
            onSuperlikeSent?.call();
          }
          break;
        }
      }
    } catch (e, stack) {
      AppLogger.error(
        'Swipe sync failed ($action)',
        tag: 'DiscoverCache',
        error: e,
        stackTrace: stack,
      );
      final err = e;
      final isLimit = _isLimitError(err);
      if (isLimit) {
        if (action == 'superlike') {
          _planLimitsService.clearCache();
        }
        if (onLimitError != null) {
          onLimitError(err);
        }
      }
      _markSyncFailed(userId);
    }
  }

  bool _isLimitError(dynamic e) {
    if (e is ApiError) {
      final code = e.responseData?['error_code'] as String?;
      final data = e.responseData?['data'] as Map<String, dynamic>?;
      final purchaseRequired = data?['purchase_required'] == true ||
          e.responseData?['purchase_required'] == true;
      return code == 'DAILY_VIEW_LIMIT_REACHED' ||
          code == 'DAILY_LIMIT_REACHED' ||
          code == 'DAILY_LIKE_LIMIT_REACHED' ||
          e.code == 429 ||
          (e.code == 403 && purchaseRequired);
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

  /// Avoid [ref.invalidate] on plan limits — it disposes the notifier while Discover still watches it.
  void _deferPlanLimitsRefresh() {
    _ref.read(planLimitsProvider.notifier).syncFromServiceCache();
    Future.microtask(() {
      unawaited(_ref.read(planLimitsProvider.notifier).refresh());
    });
  }

  void _deferSubscriptionRefresh() {
    Future.microtask(() {
      _ref.invalidate(subscriptionStatusProvider);
    });
  }

  Future<void> _upsertChatListAfterSuperlike({
    required int userId,
    required List<CachedDiscoverItem> currentList,
    String? introMessage,
    required LikeResponse response,
  }) async {
    CachedDiscoverItem? cached;
    for (final item in currentList) {
      if (item.profile.id == userId) {
        cached = item;
        break;
      }
    }
    final profile = cached?.profile;
    final name = profile == null
        ? null
        : (profile.lastName != null && profile.lastName!.isNotEmpty)
            ? '${profile.firstName} ${profile.lastName}'
            : profile.firstName;

    final intro = response.introMessage;
    final previewText = (intro?.text.isNotEmpty == true)
        ? intro!.text
        : (introMessage?.trim().isNotEmpty == true ? introMessage!.trim() : null);

    _ref.read(chatListPreviewProvider.notifier).upsertPeer(
          peerUserId: userId,
          name: name,
          avatarUrl: profile?.primaryImageUrl,
          lastMessage: previewText,
        );

    if (intro?.sent == true &&
        intro!.messageId != null &&
        previewText != null &&
        previewText.isNotEmpty) {
      final senderId = _ref.read(authProvider).user?.id;
      if (senderId != null && senderId > 0) {
        final msg = Message(
          id: intro.messageId!,
          senderId: senderId,
          receiverId: userId,
          message: previewText,
          messageType: 'text',
          createdAt: DateTime.now(),
          isRead: true,
        );
        try {
          await _ref.read(chatLocalRepositoryProvider).upsertMessage(msg, userId);
          _ref.read(chatListPreviewProvider.notifier).bumpOutgoingMessage(
                peerUserId: userId,
                previewText: previewText,
                timestamp: msg.createdAt,
              );
        } catch (e) {
          AppLogger.warning(
            'Failed to cache superlike intro locally',
            tag: 'DiscoverCache',
            error: e,
          );
        }
      }
    }
  }
}
