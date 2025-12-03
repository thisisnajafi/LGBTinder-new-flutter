import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/payment_service.dart';
import '../data/services/superlike_pack_service.dart';
import '../data/models/subscription_plan.dart';
import '../data/models/superlike_pack.dart';

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

/// Subscription Plans Provider
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return await paymentService.getPlans();
});

/// Subscription Status Provider
final subscriptionStatusProvider = FutureProvider<SubscriptionStatus?>((ref) async {
  try {
    final paymentService = ref.watch(paymentServiceProvider);
    return await paymentService.getSubscriptionStatus();
  } catch (e) {
    return null;
  }
});

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

