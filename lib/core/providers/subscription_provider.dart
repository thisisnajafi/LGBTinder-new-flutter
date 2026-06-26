import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/session_cache_providers.dart';
import '../constants/api_endpoints.dart';
import '../cache/session_data_cache_service.dart';
import '../network/subscription_meta_sync.dart';
import '../providers/api_providers.dart';
import '../services/app_logger.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/user_tier.dart';

/// Holds the current user's subscription status globally.
class SubscriptionNotifier extends StateNotifier<AppSubscriptionStatus?> {
  SubscriptionNotifier(AppSubscriptionStatus? initial) : super(initial);

  void update(AppSubscriptionStatus status) {
    if (state != status) {
      state = status;
      AppLogger.info(
        'Subscription state updated: ${status.tier.key}',
        tag: 'SubscriptionProvider',
      );
    }
  }

  bool get isPremium =>
      state?.isActive == true && state?.tier != UserTier.basid;

  bool get isGolden => state?.tier == UserTier.golden;

  bool get canMakeVideoCalls => state?.features.videoCallsEnabled == true;

  bool get hasUnlimitedLikes => state?.features.unlimitedLikes == true;

  bool get canSeeWhoLikedYou => state?.features.seeWhoLikedYou == true;

  bool get hasAdvancedFilters => state?.features.advancedFilters == true;

  bool get hasProfileBoost => state?.features.profileBoost == true;

  int? get chatMessagesVisible => state?.features.chatMessagesVisible;

  int? get messagesPerMatchDaily => state?.features.messagesPerMatchDaily;

  int get superlikesRemaining => state?.superlikesRemaining ?? 0;
}

AppSubscriptionStatus? _readCachedSubscription(SessionDataCacheService cache) {
  return cache.loadCachedSubscriptionSync();
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AppSubscriptionStatus?>(
  (ref) {
    final cache = ref.watch(sessionDataCacheServiceProvider);
    final notifier = SubscriptionNotifier(_readCachedSubscription(cache));

    SubscriptionMetaSync.instance.onUpdate = notifier.update;
    SubscriptionMetaSync.instance.onCache = (status) async {
      await cache.saveSubscription(status);
      await ref.read(cachedUserTierProvider.notifier).setTier(status.tier.key);
    };

    ref.onDispose(() {
      if (SubscriptionMetaSync.instance.onUpdate == notifier.update) {
        SubscriptionMetaSync.instance.onUpdate = null;
        SubscriptionMetaSync.instance.onCache = null;
      }
    });

    return notifier;
  },
);

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider)?.isPremium ?? false;
});

final hasUnlimitedLikesProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider)?.features.unlimitedLikes ?? false;
});

final canSeeWhoLikedYouProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider)?.features.seeWhoLikedYou ?? false;
});

final canMakeVideoCallsProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider)?.features.videoCallsEnabled ?? false;
});

/// Force refresh subscription from POST /api/subscriptions/refresh.
final subscriptionRefreshProvider = Provider<SubscriptionRefreshService>(
  (ref) => SubscriptionRefreshService(ref),
);

class SubscriptionRefreshService {
  SubscriptionRefreshService(this._ref);

  final Ref _ref;

  Future<void> refresh() async {
    try {
      final dio = _ref.read(dioClientProvider).dio;
      final response = await dio.post(ApiEndpoints.subscriptionRefresh);
      final data = response.data;
      if (data is! Map<String, dynamic>) return;

      final subscriptionJson = (data['data'] is Map<String, dynamic>
              ? (data['data'] as Map<String, dynamic>)['subscription']
              : null) ??
          (data['meta'] is Map<String, dynamic>
              ? (data['meta'] as Map<String, dynamic>)['subscription']
              : null);

      if (subscriptionJson is! Map<String, dynamic>) return;

      final sub = AppSubscriptionStatus.fromJson(subscriptionJson);
      final cache = _ref.read(sessionDataCacheServiceProvider);
      await cache.saveSubscription(sub);
      _ref.read(subscriptionProvider.notifier).update(sub);
      await _ref.read(cachedUserTierProvider.notifier).setTier(sub.tier.key);

      AppLogger.info(
        'Subscription refreshed from server: ${sub.tier.key}',
        tag: 'SubscriptionRefresh',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Subscription refresh failed',
        tag: 'SubscriptionRefresh',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
