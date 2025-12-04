import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/payment_service.dart';
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
import '../domain/use_cases/create_stripe_checkout_use_case.dart';

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

final createStripeCheckoutUseCaseProvider = Provider<CreateStripeCheckoutUseCase>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return CreateStripeCheckoutUseCase(repository);
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

