// Profile page cache-first data: cache is the single source of truth.
// On open: render only from cache (no blocking). Then refresh in background and sync UI.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/app_logger.dart';
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

PlanLimits? _parsePlanLimitsMap(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final parsed = raw.containsKey('data')
      ? PlanLimits.tryParse(raw)
      : PlanLimits.tryParse({'data': raw});
  if (parsed == null) {
    profileLog('parsePlanLimitsMap failed: invalid payload');
  }
  return parsed;
}

PlanLimits _fallbackPlanLimits() {
  return PlanLimits.fromJson({
    'data': {
      'plan_info': {
        'plan_id': 1,
        'plan_name': 'basic',
        'is_premium': false,
      },
      'limits': {
        'swipes': {'daily_limit': 50, 'is_unlimited': false},
        'likes': {'daily_limit': 50, 'is_unlimited': false},
        'superlikes': {'daily_limit': 1, 'is_unlimited': false},
        'messages': {
          'max_conversations': 999,
          'is_unlimited': true,
        },
      },
      'usage': {
        'swipes': {
          'used_today': 0,
          'limit': 50,
          'remaining': 50,
          'is_unlimited': false,
        },
        'likes': {
          'used_today': 0,
          'limit': 50,
          'remaining': 50,
          'is_unlimited': false,
        },
        'superlikes': {
          'used_today': 0,
          'limit': 1,
          'remaining': 1,
          'is_unlimited': false,
        },
        'messages': {
          'sent_today': 0,
          'active_conversations': 0,
          'conversation_limit': 999,
          'is_unlimited': true,
        },
      },
      'features': {
        'advanced_filters': false,
        'see_who_liked_me': false,
        'rewind': false,
        'passport': false,
        'boost': false,
        'read_receipts': false,
        'video_calls': false,
        'incognito_mode': false,
        'ad_free': false,
        'priority_likes': false,
        'ai_matching': false,
      },
      'timestamps': {
        'resets_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'checked_at': DateTime.now().toIso8601String(),
      },
    },
  });
}

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
    profileLog('loadFromCache: reading ${CacheKeys.myProfile} + ${CacheKeys.planLimits}');
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

    profileLog(
      'loadFromCache: profileMap=${profileMap != null ? "hit (${profileMap.length} keys)" : "miss"}, '
      'planLimitsMap=${planLimitsMap != null ? "hit" : "miss"}',
    );

    if (profileMap == null) {
      profileLog('loadFromCache: no cached profile — waiting for refresh()');
      return;
    }

    try {
      final profile = UserProfile.fromJson(profileMap);
      final planLimits =
          _parsePlanLimitsMap(planLimitsMap) ?? _fallbackPlanLimits();
      profileLog(
        'loadFromCache: OK userId=${profile.id} email=${profile.email} '
        'planLimits=${planLimitsMap != null ? "from cache" : "fallback"}',
      );
      state = AsyncValue.data(
        ProfilePageData(profile: profile, planLimits: planLimits),
      );
    } catch (e, st) {
      profileLog('loadFromCache: UserProfile.fromJson failed — cache may be corrupt');
      profileLogError('loadFromCache parse', e, st);
    }
  }

  /// 2) Fetch from server, then update cache and state together. Call after navigation.
  Future<void> refresh() async {
    if (_isRefreshing) {
      profileLog('refresh: skipped (already in progress)');
      return;
    }
    _isRefreshing = true;
    profileLog('refresh: start (hasValue=${state.hasValue} hasError=${state.hasError})');

    try {
      UserProfile? profile;
      Object? profileError;
      try {
        profileLog('refresh: GET /profile (getMyProfile)');
        profile = await _profileService.getMyProfile();
        profileLog(
          'refresh: getMyProfile OK id=${profile.id} '
          'name=${profile.firstName} images=${profile.images?.length ?? 0}',
        );
      } catch (e, st) {
        profileError = e;
        profileLogError('refresh getMyProfile', e, st);
        profile = state.valueOrNull?.profile;
        if (profile == null) {
          profileLog('refresh: no cache fallback — surfacing error to UI');
          state = AsyncValue.error(e, st);
          return;
        }
        profileLog(
          'refresh: using cached profile id=${profile.id} after network failure',
        );
      }

      PlanLimits planLimits;
      try {
        profileLog('refresh: GET plan limits');
        planLimits = await _planLimitsService.getPlanLimits(forceRefresh: true);
        profileLog('refresh: plan limits OK plan=${planLimits.planInfo?.planName}');
      } catch (e, st) {
        profileLogError('refresh planLimits', e, st);
        planLimits =
            state.valueOrNull?.planLimits ?? _fallbackPlanLimits();
        profileLog('refresh: using ${state.hasValue ? "cached" : "fallback"} plan limits');
      }

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
      profileLog('refresh: cache written');

      state = AsyncValue.data(
        ProfilePageData(profile: profile, planLimits: planLimits),
      );
      profileLog('refresh: complete — state=data');

      if (profileError != null) {
        profileLog(
          'refresh: profile API failed but UI kept from cache (non-fatal)',
        );
      }
    } catch (e, st) {
      profileLogError('refresh unexpected', e, st);
      if (!state.hasValue) {
        profileLog('refresh: surfacing error (no cached value)');
        state = AsyncValue.error(e, st);
      } else {
        profileLog('refresh: error ignored (keeping existing data)');
      }
    } finally {
      _isRefreshing = false;
      profileLog('refresh: end');
    }
  }

  void _init() {
    profileLog('ProfilePageCacheNotifier: init');
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
