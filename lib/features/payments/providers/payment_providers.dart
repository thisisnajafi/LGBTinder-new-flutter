import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/payment_service.dart';
import '../data/services/plan_limits_service.dart';
import '../data/services/superlike_pack_service.dart';
import '../data/repositories/payment_repository.dart';
import '../data/models/subscription_plan.dart';
import '../data/models/superlike_pack.dart';
import '../domain/use_cases/get_subscription_plans_use_case.dart';
import '../domain/use_cases/purchase_subscription_use_case.dart';
import '../domain/use_cases/cancel_subscription_use_case.dart';
import '../domain/use_cases/restore_purchases_use_case.dart';
import '../domain/use_cases/validate_receipt_use_case.dart';
import '../domain/use_cases/get_superlike_packs_use_case.dart';
import '../domain/use_cases/get_subscription_status_use_case.dart';

/// Payment Service Provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentService(apiService);
});

/// Superlike Pack Service Provider
final superlikePackServiceProvider = Provider<SuperlikePackService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SuperlikePackService(apiService);
});

/// Payment Repository Provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  final superlikePackService = ref.watch(superlikePackServiceProvider);
  return PaymentRepository(paymentService, superlikePackService);
});

/// Use Case Providers
final getSubscriptionPlansUseCaseProvider = Provider<GetSubscriptionPlansUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return GetSubscriptionPlansUseCase(repository);
});

final purchaseSubscriptionUseCaseProvider = Provider<PurchaseSubscriptionUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PurchaseSubscriptionUseCase(repository);
});

final cancelSubscriptionUseCaseProvider = Provider<CancelSubscriptionUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return CancelSubscriptionUseCase(repository);
});

final restorePurchasesUseCaseProvider = Provider<RestorePurchasesUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return RestorePurchasesUseCase(repository);
});

final validateReceiptUseCaseProvider = Provider<ValidateReceiptUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return ValidateReceiptUseCase(repository);
});

final getSuperlikePacksUseCaseProvider = Provider<GetSuperlikePacksUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return GetSuperlikePacksUseCase(repository);
});

final getSubscriptionStatusUseCaseProvider = Provider<GetSubscriptionStatusUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return GetSubscriptionStatusUseCase(repository);
});

/// Subscription Plans Provider
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return await paymentService.getPlans();
});

/// Subscription Status Provider
/// 
/// Task 3.3.2 (Phase 4): Enhanced with auto-refresh capability
/// Use ref.refresh(subscriptionStatusProvider) to force refresh
final subscriptionStatusProvider = FutureProvider<SubscriptionStatus?>((ref) async {
  try {
    final paymentService = ref.watch(paymentServiceProvider);
    return await paymentService.getSubscriptionStatus();
  } catch (e) {
    return null;
  }
});

/// Subscription Sync Service Provider
/// 
/// Task 3.3.2: Provides subscription status sync functionality
/// Call methods on this provider to refresh subscription status
final subscriptionSyncProvider = Provider<SubscriptionSyncService>((ref) {
  return SubscriptionSyncService(ref);
});

/// Subscription Sync Service
/// 
/// Task 3.3.2 (Phase 4): Handles subscription status synchronization
/// 
/// Usage:
/// ```dart
/// // In a widget
/// final syncService = ref.read(subscriptionSyncProvider);
/// await syncService.refreshStatus(); // Manual refresh
/// syncService.schedulePeriodicRefresh(Duration(minutes: 30)); // Auto-refresh
/// ```
class SubscriptionSyncService {
  final Ref _ref;
  bool _isPeriodicRefreshActive = false;

  SubscriptionSyncService(this._ref);

  /// Refresh subscription status immediately
  Future<SubscriptionStatus?> refreshStatus() async {
    return await _ref.refresh(subscriptionStatusProvider.future);
  }

  /// Invalidate cached status (forces next read to fetch fresh data)
  void invalidateStatus() {
    _ref.invalidate(subscriptionStatusProvider);
  }

  /// Get current subscription status (cached if available)
  SubscriptionStatus? get currentStatus {
    return _ref.read(subscriptionStatusProvider).valueOrNull;
  }

  /// Check if user has active subscription
  bool get hasActiveSubscription {
    return currentStatus?.isActive == true;
  }

  /// Check if user is premium
  bool get isPremium {
    return hasActiveSubscription;
  }

  /// Schedule periodic refresh (call once during app initialization)
  /// 
  /// Note: This is a simple implementation. For production, consider using
  /// a background task scheduler or listening to app lifecycle events.
  void schedulePeriodicRefresh(Duration interval) {
    if (_isPeriodicRefreshActive) return;
    _isPeriodicRefreshActive = true;

    Future.doWhile(() async {
      await Future.delayed(interval);
      if (!_isPeriodicRefreshActive) return false;
      
      try {
        await refreshStatus();
      } catch (e) {
        // Silently fail - will retry on next interval
      }
      return _isPeriodicRefreshActive;
    });
  }

  /// Stop periodic refresh
  void stopPeriodicRefresh() {
    _isPeriodicRefreshActive = false;
  }

  /// Handle subscription change notification from push notification
  /// 
  /// Call this when receiving a push notification about subscription changes
  Future<void> onSubscriptionChangeNotification() async {
    await refreshStatus();
    // Also refresh plan limits as subscription may affect limits
    _ref.invalidate(planLimitsServiceProvider);
  }
}

/// Available Superlike Packs Provider
final availableSuperlikePacksProvider = FutureProvider<List<SuperlikePack>>((ref) async {
  final superlikeService = ref.watch(superlikePackServiceProvider);
  return await superlikeService.getAvailablePacks();
});

/// User Superlike Packs Provider
final userSuperlikePacksProvider = FutureProvider<List<UserSuperlikePack>>((ref) async {
  final superlikeService = ref.watch(superlikePackServiceProvider);
  return await superlikeService.getUserPacks();
});

/// Total Superlikes Provider (sum of remaining counts)
final totalSuperlikesProvider = FutureProvider<int>((ref) async {
  final userPacks = await ref.watch(userSuperlikePacksProvider.future);
  return userPacks.fold<int>(0, (sum, pack) => sum + pack.remainingCount);
});

