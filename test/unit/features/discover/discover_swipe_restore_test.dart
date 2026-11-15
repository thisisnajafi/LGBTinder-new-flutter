// Discover: a like / pass / super like is shown at once and sent in the
// background. These tests pin what happens when the send fails.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/cache/cache_invalidator.dart';
import 'package:lgbtindernew/core/cache/session_data_cache_service.dart';
import 'package:lgbtindernew/features/discover/data/models/cached_discover_item.dart';
import 'package:lgbtindernew/features/discover/data/models/discovery_profile.dart';
import 'package:lgbtindernew/features/discover/data/services/discovery_service.dart';
import 'package:lgbtindernew/features/discover/providers/discover_cache_provider.dart';
import 'package:lgbtindernew/features/discover/providers/discovery_providers.dart';
import 'package:lgbtindernew/features/matching/data/models/like.dart';
import 'package:lgbtindernew/features/matching/data/services/likes_service.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';
import 'package:lgbtindernew/shared/services/cache_service.dart';

/// Likes repository whose answers the test scripts.
class _ScriptedLikesService extends Fake implements LikesService {
  Object? failWith;
  int likeCalls = 0;
  int dislikeCalls = 0;

  @override
  Future<LikeResponse> likeUser(int likedUserId) async {
    likeCalls++;
    final error = failWith;
    if (error != null) throw error;
    return LikeResponse(isMatch: false);
  }

  @override
  Future<DislikeResponse> dislikeUser(int likedUserId) async {
    dislikeCalls++;
    final error = failWith;
    if (error != null) throw error;
    return DislikeResponse();
  }
}

class _FakePlanLimitsService extends Fake implements PlanLimitsService {
  final List<String> increments = <String>[];

  @override
  void incrementUsage(String limitType) => increments.add(limitType);

  @override
  void clearCache() {}
}

/// Empty cache; writes are dropped.
class _FakeCacheService extends Fake implements CacheService {
  @override
  Future<T?> getCached<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? customExpiry,
  }) async {
    return null;
  }

  @override
  Future<void> cacheEncodedJson(
    String key,
    String encoded, {
    Duration? duration,
  }) async {}
}

class _FakeDiscoveryService extends Fake implements DiscoveryService {}

class _FakeCacheInvalidator extends Fake implements CacheInvalidator {}

class _FakeSessionCache extends Fake implements SessionDataCacheService {}

DiscoveryProfile _profile(int id) =>
    DiscoveryProfile(id: id, firstName: 'User $id');

void main() {
  group('shouldRestoreSwipeAfterFailure', () {
    test('restores on server errors, timeouts and unexpected exceptions', () {
      expect(
        shouldRestoreSwipeAfterFailure(
          ApiError(code: 500, message: 'boom'),
          isLimitError: false,
        ),
        isTrue,
      );
      expect(
        shouldRestoreSwipeAfterFailure(
          ApiError(code: 503, message: 'down'),
          isLimitError: false,
        ),
        isTrue,
      );
      expect(
        shouldRestoreSwipeAfterFailure(
          ApiError(code: 408, message: 'timeout'),
          isLimitError: false,
        ),
        isTrue,
      );
      expect(
        shouldRestoreSwipeAfterFailure(
          StateError('parse failed'),
          isLimitError: false,
        ),
        isTrue,
      );
      expect(
        shouldRestoreSwipeAfterFailure(
          ApiError(message: 'no status code'),
          isLimitError: false,
        ),
        isTrue,
      );
    });

    test('restores when the plan limit rejected the swipe', () {
      expect(
        shouldRestoreSwipeAfterFailure(
          ApiError(code: 403, message: 'limit'),
          isLimitError: true,
        ),
        isTrue,
      );
    });

    test('keeps the swipe when offline: it is sent on reconnect', () {
      expect(
        shouldRestoreSwipeAfterFailure(
          ApiError(code: 0, message: 'offline'),
          isLimitError: false,
        ),
        isFalse,
      );
    });

    test('keeps the swipe on other 4xx answers so it cannot loop', () {
      for (final code in [400, 404, 409, 422]) {
        expect(
          shouldRestoreSwipeAfterFailure(
            ApiError(code: code, message: 'rejected'),
            isLimitError: false,
          ),
          isFalse,
          reason: 'HTTP $code',
        );
      }
    });
  });

  group('restoreSwipedDiscoverItem', () {
    test('undoes the swipe and keeps the card in place', () {
      final items = [
        CachedDiscoverItem(
          profile: _profile(1),
          interactionState: DiscoverInteractionState.disliked,
        ),
        CachedDiscoverItem(
          profile: _profile(2),
          interactionState: DiscoverInteractionState.liked,
          syncStatus: DiscoverSyncStatus.pending,
        ),
        CachedDiscoverItem(profile: _profile(3)),
      ];

      final restored = restoreSwipedDiscoverItem(items, 2)!;

      expect(restored.map((e) => e.id), [1, 2, 3]);
      expect(restored[1].interactionState, DiscoverInteractionState.none);
      expect(restored[1].syncStatus, DiscoverSyncStatus.synced);
      // Untouched entries are the same objects; the input list is not edited.
      expect(restored[0], same(items[0]));
      expect(items[1].interactionState, DiscoverInteractionState.liked);
    });

    test('returns null for an unknown or unswiped user', () {
      final items = [CachedDiscoverItem(profile: _profile(1))];
      expect(restoreSwipedDiscoverItem(items, 99), isNull);
      expect(restoreSwipedDiscoverItem(items, 1), isNull);
    });
  });

  group('DiscoverCacheNotifier optimistic swipe', () {
    late _ScriptedLikesService likes;
    late _FakePlanLimitsService limits;
    late ProviderContainer container;
    late StateNotifierProvider<DiscoverCacheNotifier, DiscoverCacheState>
        provider;

    setUp(() async {
      likes = _ScriptedLikesService();
      limits = _FakePlanLimitsService();
      provider =
          StateNotifierProvider<DiscoverCacheNotifier, DiscoverCacheState>(
        (ref) => DiscoverCacheNotifier(
          ref,
          _FakeDiscoveryService(),
          likes,
          limits,
          _FakeCacheService(),
          _FakeCacheInvalidator(),
          _FakeSessionCache(),
        ),
      );
      container = ProviderContainer();
      addTearDown(container.dispose);

      // Let the constructor's cache load finish before seeding.
      container.read(provider);
      await pumpEventQueue();
      container
          .read(provider.notifier)
          .debugSeedProfiles([_profile(1), _profile(2), _profile(3)]);
    });

    List<int> stackIds() =>
        container.read(provider).stack.map((p) => p.id).toList();

    test('a like advances the stack before the server answers', () {
      container.read(provider.notifier).recordSwipe(1, 'like');

      // Synchronous: no await between the tap and the next card.
      expect(stackIds(), [2, 3]);
      expect(container.read(provider).lastSwipedUserId, 1);
    });

    test('a like that the server fails gives the card back', () async {
      likes.failWith = ApiError(code: 500, message: 'Server error');
      container
          .read(discoveryActedOnUserIdsProvider.notifier)
          .update((ids) => {...ids, 1});
      final restoredWith = <Object>[];

      container.read(provider.notifier).recordSwipe(
            1,
            'like',
            onSwipeRestored: restoredWith.add,
          );
      expect(stackIds(), [2, 3]);

      await pumpEventQueue();

      expect(likes.likeCalls, 1);
      expect(stackIds(), [1, 2, 3], reason: 'card is back at the front');
      expect(restoredWith, hasLength(1));
      expect(restoredWith.single, isA<ApiError>());
      final item = container.read(provider).items.first;
      expect(item.interactionState, DiscoverInteractionState.none);
      expect(item.syncStatus, DiscoverSyncStatus.synced);
      // Rewind must not point at a swipe that never happened.
      expect(container.read(provider).lastSwipedUserId, isNull);
      // The profile can be shown and swiped again.
      expect(container.read(discoveryActedOnUserIdsProvider), isNot(contains(1)));
      // Nothing was counted against the plan.
      expect(limits.increments, isEmpty);
    });

    test('a pass that throws an unexpected error gives the card back',
        () async {
      likes.failWith = StateError('bad json');
      var restored = 0;

      container.read(provider.notifier).recordSwipe(
            1,
            'dislike',
            onSwipeRestored: (_) => restored++,
          );
      await pumpEventQueue();

      expect(likes.dislikeCalls, 1);
      expect(stackIds(), [1, 2, 3]);
      expect(restored, 1);
    });

    test('the restored card can be liked again and then stays swiped',
        () async {
      likes.failWith = ApiError(code: 502, message: 'Bad gateway');
      container.read(provider.notifier).recordSwipe(1, 'like');
      await pumpEventQueue();
      expect(stackIds(), [1, 2, 3]);

      likes.failWith = null;
      container.read(provider.notifier).recordSwipe(1, 'like');
      await pumpEventQueue();

      expect(likes.likeCalls, 2);
      expect(stackIds(), [2, 3]);
      expect(limits.increments, ['swipes', 'likes']);
    });

    test('a plan-limit rejection gives the card back and reports the limit',
        () async {
      likes.failWith = ApiError(
        code: 403,
        message: 'Daily limit reached',
        responseData: const {'error_code': 'DAILY_LIMIT_REACHED'},
      );
      final limitErrors = <dynamic>[];
      var restored = 0;

      container.read(provider.notifier).recordSwipe(
            1,
            'like',
            onLimitError: limitErrors.add,
            onSwipeRestored: (_) => restored++,
          );
      await pumpEventQueue();

      expect(stackIds(), [1, 2, 3]);
      expect(limitErrors, hasLength(1));
      // The limit dialog explains it; no second message.
      expect(restored, 0);
    });

    test('an offline like stays swiped and is reported as queued', () async {
      likes.failWith = ApiError(code: 0, message: 'No internet');
      var queued = 0;
      var restored = 0;

      container.read(provider.notifier).recordSwipe(
            1,
            'like',
            onOfflineQueued: () => queued++,
            onSwipeRestored: (_) => restored++,
          );
      await pumpEventQueue();

      expect(stackIds(), [2, 3]);
      expect(queued, 1);
      expect(restored, 0);
    });

    test('a like the server refuses (422) stays swiped, marked failed',
        () async {
      likes.failWith = ApiError(code: 422, message: 'Already liked');
      var restored = 0;

      container.read(provider.notifier).recordSwipe(
            1,
            'like',
            onSwipeRestored: (_) => restored++,
          );
      await pumpEventQueue();

      expect(stackIds(), [2, 3]);
      expect(restored, 0);
      expect(
        container.read(provider).items.first.syncStatus,
        DiscoverSyncStatus.failed,
      );
    });

    test('a successful like stays swiped and is counted', () async {
      var restored = 0;

      container.read(provider.notifier).recordSwipe(
            1,
            'like',
            onSwipeRestored: (_) => restored++,
          );
      await pumpEventQueue();

      expect(stackIds(), [2, 3]);
      expect(restored, 0);
      expect(limits.increments, ['swipes', 'likes']);
      expect(
        container.read(provider).items.first.syncStatus,
        DiscoverSyncStatus.synced,
      );
    });
  });
}
