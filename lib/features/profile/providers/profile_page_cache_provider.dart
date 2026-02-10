// Profile page cache-first data: cache is the single source of truth.
// On open: render only from cache (no blocking). Then refresh in background and sync UI.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/services/cache_service.dart';
import '../../payments/data/models/plan_limits.dart';
import '../../payments/data/services/plan_limits_service.dart';
import '../data/models/user_profile.dart';
import '../data/services/profile_service.dart';
import 'profile_providers.dart';

/// Immutable snapshot of Profile page data (only cached values are shown in UI).
class ProfilePageData {
  final UserProfile profile;
  final PlanLimits planLimits;

  const ProfilePageData({
    required this.profile,
    required this.planLimits,
  });
}

/// Cache-first provider for the Profile page (own profile only).
/// State is only ever set from cache or from a full successful fetch (never partial).
final profilePageCacheProvider =
    StateNotifierProvider<ProfilePageCacheNotifier, AsyncValue<ProfilePageData>>((ref) {
  return ProfilePageCacheNotifier(
    ref.read(profileServiceProvider),
    ref.read(planLimitsServiceProvider),
    ref.read(cacheServiceProvider),
  );
});

class ProfilePageCacheNotifier extends StateNotifier<AsyncValue<ProfilePageData>> {
  ProfilePageCacheNotifier(
    this._profileService,
    this._planLimitsService,
    this._cacheService,
  ) : super(const AsyncValue.loading()) {
    _init();
  }

  final ProfileService _profileService;
  final PlanLimitsService _planLimitsService;
  final CacheService _cacheService;

  bool _isRefreshing = false;

  /// 1) Load from cache only — no network. UI renders from this.
  Future<void> loadFromCache() async {
    final profileMap = await _cacheService.getCached<Map<String, dynamic>>(
      CacheKeys.myProfile,
      (json) => Map<String, dynamic>.from(json),
      customExpiry: CacheDuration.profile,
    );
    final planLimitsMap = await _cacheService.getCached<Map<String, dynamic>>(
      CacheKeys.planLimits,
      (json) => Map<String, dynamic>.from(json),
      customExpiry: CacheDuration.profile,
    );

    if (profileMap != null && planLimitsMap != null) {
      try {
        final profile = UserProfile.fromJson(profileMap);
        // PlanLimits.fromJson expects { 'data': { plan_info, limits, ... } }
        final planLimits = PlanLimits.fromJson(planLimitsMap);
        state = AsyncValue.data(ProfilePageData(profile: profile, planLimits: planLimits));
      } catch (_) {
        // Corrupted cache — leave state as loading
      }
    }
  }

  /// 2) Fetch from server, then update cache and state together. Call after navigation.
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final results = await Future.wait([
        _profileService.getMyProfile(),
        _planLimitsService.getPlanLimits(forceRefresh: true),
      ]);
      final profile = results[0] as UserProfile;
      final planLimits = results[1] as PlanLimits;

      await Future.wait([
        _cacheService.cacheData(
          CacheKeys.myProfile,
          profile.toJson(),
          duration: CacheDuration.profile,
        ),
        _cacheService.cacheData(
          CacheKeys.planLimits,
          {'data': planLimits.toJson()},
          duration: CacheDuration.profile,
        ),
      ]);

      state = AsyncValue.data(ProfilePageData(profile: profile, planLimits: planLimits));
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  void _init() {
    Future.microtask(() async {
      await loadFromCache();
      unawaited(refresh());
    });
  }

  /// Invalidate cache (e.g. after profile edit or logout).
  Future<void> invalidate() async {
    await _cacheService.clearCache(CacheKeys.myProfile);
    await _cacheService.clearCache(CacheKeys.planLimits);
    state = const AsyncValue.loading();
    await loadFromCache();
    unawaited(refresh());
  }
}
