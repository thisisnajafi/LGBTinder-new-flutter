import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../../features/payments/providers/payment_providers.dart';
import '../../shared/models/user_tier.dart';
import '../cache/cache_manager.dart';
import '../cache/session_cache_providers.dart';
import '../providers/subscription_provider.dart';
import '../services/app_logger.dart';

/// Coordinates one-time (per session) startup cache priming.
class StartupCacheService {
  StartupCacheService(this._ref);

  final Ref _ref;
  DateTime? _lastPrimeAt;
  bool _isPriming = false;

  bool get isPriming => _isPriming;

  DateTime? get lastPrimeAt => _lastPrimeAt;

  Future<void> primeCache() async {
    if (_isPriming) return;

    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    _isPriming = true;
    try {
      await Future.wait([
        _fetchAndCacheSuperlikePacks(),
        _fetchAndCacheSubscription(),
        _fetchAndCacheOwnProfile(),
        _ref.read(subscriptionRefreshProvider).refresh(),
      ]);
      _lastPrimeAt = DateTime.now();
      AppLogger.info('Startup cache primed', tag: 'StartupCache');
    } catch (e, stack) {
      AppLogger.error(
        'Startup cache prime failed',
        tag: 'StartupCache',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _isPriming = false;
    }
  }

  bool shouldReprimeOnForeground() {
    if (_lastPrimeAt == null) return true;
    return DateTime.now().difference(_lastPrimeAt!) >
        const Duration(minutes: 5);
  }

  Future<void> _fetchAndCacheSuperlikePacks() async {
    final sessionCache = _ref.read(sessionDataCacheServiceProvider);
    final superlikeService = _ref.read(superlikePackServiceProvider);
    final planLimitsService = _ref.read(planLimitsServiceProvider);

    try {
      final packs = await superlikeService.getAvailablePacks();
      await sessionCache.setSuperlikePacks(packs);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to cache superlike packs',
        tag: 'StartupCache',
        error: e,
        stackTrace: stack,
      );
    }

    try {
      final limits = await planLimitsService.getPlanLimits(forceRefresh: true);
      final remaining = limits.effectiveSuperlikeInfo.totalRemaining;
      await sessionCache.setSuperlikesRemaining(remaining);
      _ref.read(superlikesRemainingProvider.notifier).setCount(remaining);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to cache superlike remaining count from plan-limits',
        tag: 'StartupCache',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _fetchAndCacheSubscription() async {
    final sessionCache = _ref.read(sessionDataCacheServiceProvider);
    final paymentService = _ref.read(paymentServiceProvider);

    try {
      final status = await paymentService.getSubscriptionStatus();
      await sessionCache.setSubscriptionStatus(status);
      final tier = status.tier ??
          userTierFromPlan(planId: status.planId, planName: status.planName)
              .key;
      await sessionCache.setUserTier(tier);
      _ref.read(cachedUserTierProvider.notifier).setTier(tier);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to cache subscription status',
        tag: 'StartupCache',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _fetchAndCacheOwnProfile() async {
    try {
      await _ref.read(appCacheManagerProvider).revalidateOwnProfile();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to revalidate own profile on startup',
        tag: 'StartupCache',
        error: e,
        stackTrace: stack,
      );
    }
  }
}

final startupCacheServiceProvider = Provider<StartupCacheService>((ref) {
  return StartupCacheService(ref);
});
