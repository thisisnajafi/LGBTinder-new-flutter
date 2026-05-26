import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/matching/data/models/match.dart';
import '../../features/profile/data/models/user_profile.dart';
import 'cache_manager.dart';

// ── Other users' profiles ───────────────────────────────────────────────────

final userProfileProvider = StateNotifierProvider.family<
    UserProfileCacheNotifier, AsyncValue<UserProfile>, String>(
  (ref, userId) {
    final notifier = UserProfileCacheNotifier();
    Future.microtask(() {
      ref.read(appCacheManagerProvider).revalidate(userId);
    });
    return notifier;
  },
);

class UserProfileCacheNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  UserProfileCacheNotifier() : super(const AsyncValue.loading());

  void applyCached(UserProfile profile) {
    state = AsyncValue.data(profile);
  }

  void applyFresh(UserProfile profile) {
    state = AsyncValue.data(profile);
  }

  void applyError(Object error, StackTrace stackTrace) {
    if (!state.hasValue) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// ── Own profile ─────────────────────────────────────────────────────────────

final ownProfileProvider =
    StateNotifierProvider<OwnProfileCacheNotifier, AsyncValue<UserProfile>>(
  (ref) {
    final notifier = OwnProfileCacheNotifier();
    Future.microtask(() {
      ref.read(appCacheManagerProvider).revalidateOwnProfile();
    });
    return notifier;
  },
);

class OwnProfileCacheNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  OwnProfileCacheNotifier() : super(const AsyncValue.loading());

  void applyCached(UserProfile profile) {
    state = AsyncValue.data(profile);
  }

  void applyFresh(UserProfile profile) {
    state = AsyncValue.data(profile);
  }
}

// ── Match list (cache-first) ────────────────────────────────────────────────

final cachedMatchesProvider =
    StateNotifierProvider<CachedMatchesNotifier, AsyncValue<List<Match>>>(
  (ref) => CachedMatchesNotifier(),
);

class CachedMatchesNotifier extends StateNotifier<AsyncValue<List<Match>>> {
  CachedMatchesNotifier() : super(const AsyncValue.loading());

  void applyCached(List<Match> matches) {
    state = AsyncValue.data(matches);
  }

  void applyFresh(List<Match> matches) {
    state = AsyncValue.data(matches);
  }
}
