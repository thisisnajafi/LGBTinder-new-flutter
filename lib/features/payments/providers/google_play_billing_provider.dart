import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/providers/feature_flags_provider.dart';
import '../../../core/services/offline_payment_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/connectivity_service.dart';
import '../data/services/google_play_billing_service.dart';
import '../domain/repositories/google_play_repository.dart';
import '../domain/use_cases/initiate_google_purchase_use_case.dart';

// Provider for Offline Payment Service
final offlinePaymentServiceProvider = Provider<OfflinePaymentService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflinePaymentService(apiService, prefs);
});

// Provider for connectivity status
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectivityStream;
});

// Provider for Google Play Billing Service
final googlePlayBillingServiceProvider = Provider<GooglePlayBillingService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final offlineService = ref.watch(offlinePaymentServiceProvider);
  return GooglePlayBillingService(apiService, offlineService);
});

// Provider for Google Play Repository
final googlePlayRepositoryProvider = Provider<GooglePlayRepository>((ref) {
  final billingService = ref.watch(googlePlayBillingServiceProvider);
  return GooglePlayRepositoryImpl(billingService);
});

// Provider for billing availability state
final billingAvailabilityProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return repository.billingAvailability;
});

// Provider for purchase updates
final purchaseUpdatesProvider = StreamProvider<List<PurchaseDetails>>((ref) {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return repository.purchaseUpdates;
});

// Provider for billing errors
final billingErrorsProvider = StreamProvider<String>((ref) {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return repository.errors;
});

// Provider for subscription products
final subscriptionProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return repository.querySubscriptionProducts();
});

// Provider for one-time products
final oneTimeProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return repository.queryOneTimeProducts();
});

// Provider for InitiateGooglePurchaseUseCase
final initiateGooglePurchaseUseCaseProvider = Provider<InitiateGooglePurchaseUseCase>((ref) {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return InitiateGooglePurchaseUseCase(repository);
});

// State notifier for purchase state management
class GooglePlayPurchaseNotifier extends StateNotifier<GooglePlayPurchaseState> {
  final InitiateGooglePurchaseUseCase _purchaseUseCase;

  GooglePlayPurchaseNotifier(this._purchaseUseCase)
      : super(const GooglePlayPurchaseState.initial());

  Future<void> initiatePurchase(String productId, bool isSubscription) async {
    state = const GooglePlayPurchaseState.loading();

    final result = await _purchaseUseCase.execute(productId, isSubscription);

    if (result.isSuccess) {
      state = GooglePlayPurchaseState.success(result.productDetails!);
    } else {
      state = GooglePlayPurchaseState.error(result.errorMessage!);
    }
  }

  void reset() {
    state = const GooglePlayPurchaseState.initial();
  }
}

// Purchase state
class GooglePlayPurchaseState {
  final bool isLoading;
  final bool isSuccess;
  final ProductDetails? productDetails;
  final String? errorMessage;

  const GooglePlayPurchaseState._({
    this.isLoading = false,
    this.isSuccess = false,
    this.productDetails,
    this.errorMessage,
  });

  const GooglePlayPurchaseState.initial() : this._();

  const GooglePlayPurchaseState.loading() : this._(isLoading: true);

  const GooglePlayPurchaseState.success(ProductDetails productDetails)
      : this._(isSuccess: true, productDetails: productDetails);

  const GooglePlayPurchaseState.error(String errorMessage)
      : this._(errorMessage: errorMessage);
}

// Provider for purchase notifier
final googlePlayPurchaseProvider = StateNotifierProvider<GooglePlayPurchaseNotifier, GooglePlayPurchaseState>((ref) {
  final purchaseUseCase = ref.watch(initiateGooglePurchaseUseCaseProvider);
  return GooglePlayPurchaseNotifier(purchaseUseCase);
});

// Provider for current purchases
final currentPurchasesProvider = FutureProvider<List<PurchaseDetails>>((ref) async {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return repository.getCurrentPurchases();
});

// Provider for billing availability check
final isBillingAvailableProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return repository.isBillingAvailable();
});

// Provider for purchase restoration
final purchaseRestorationProvider = FutureProvider.autoDispose<void>((ref) async {
  final repository = ref.watch(googlePlayRepositoryProvider);
  final isRestorationEnabled = ref.watch(purchaseRestorationEnabledProvider);

  if (isRestorationEnabled) {
    await repository.restorePurchases();
  }
});

// Provider for pending purchases count
final pendingPurchasesCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(googlePlayRepositoryProvider);
  return await repository.getCurrentPurchases().then((purchases) {
    // In a real implementation, you'd check for pending status
    return 0; // Placeholder
  });
});

// Provider for offline purchase processing
final offlinePurchaseProcessorProvider = FutureProvider.autoDispose<void>((ref) async {
  final repository = ref.watch(googlePlayRepositoryProvider);
  final isOnline = await ref.watch(connectivityStatusProvider.future);

  if (isOnline) {
    // Process pending purchases when back online
    await repository.restorePurchases();
  }
});

// Utility provider for billing initialization
final googlePlayBillingInitializerProvider = Provider<void>((ref) {
  final repository = ref.watch(googlePlayRepositoryProvider);
  // Initialize billing when this provider is first accessed
  repository.initialize();
});
