import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Payment provider - manages payment and subscription state
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final getSubscriptionPlansUseCase = ref.watch(getSubscriptionPlansUseCaseProvider);
  final purchaseSubscriptionUseCase = ref.watch(purchaseSubscriptionUseCaseProvider);
  final cancelSubscriptionUseCase = ref.watch(cancelSubscriptionUseCaseProvider);
  final restorePurchasesUseCase = ref.watch(restorePurchasesUseCaseProvider);
  final validateReceiptUseCase = ref.watch(validateReceiptUseCaseProvider);
  final getSuperlikePacksUseCase = ref.watch(getSuperlikePacksUseCaseProvider);
  final getSubscriptionStatusUseCase = ref.watch(getSubscriptionStatusUseCaseProvider);
  final createStripeCheckoutUseCase = ref.watch(createStripeCheckoutUseCaseProvider);

  return PaymentNotifier(
    getSubscriptionPlansUseCase: getSubscriptionPlansUseCase,
    purchaseSubscriptionUseCase: purchaseSubscriptionUseCase,
    cancelSubscriptionUseCase: cancelSubscriptionUseCase,
    restorePurchasesUseCase: restorePurchasesUseCase,
    validateReceiptUseCase: validateReceiptUseCase,
    getSuperlikePacksUseCase: getSuperlikePacksUseCase,
    getSubscriptionStatusUseCase: getSubscriptionStatusUseCase,
    createStripeCheckoutUseCase: createStripeCheckoutUseCase,
  );
});

/// Payment state
class PaymentState {
  final List<SubscriptionPlan> subscriptionPlans;
  final List<SuperlikePack> superlikePacks;
  final SubscriptionStatus? subscriptionStatus;
  final bool isLoading;
  final bool isPurchasing;
  final bool isRestoring;
  final String? error;
  final bool hasActiveSubscription;
  final String? selectedPlanId;
  final Map<String, dynamic>? checkoutSession;

  PaymentState({
    this.subscriptionPlans = const [],
    this.superlikePacks = const [],
    this.subscriptionStatus,
    this.isLoading = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.error,
    this.hasActiveSubscription = false,
    this.selectedPlanId,
    this.checkoutSession,
  });

  PaymentState copyWith({
    List<SubscriptionPlan>? subscriptionPlans,
    List<SuperlikePack>? superlikePacks,
    SubscriptionStatus? subscriptionStatus,
    bool? isLoading,
    bool? isPurchasing,
    bool? isRestoring,
    String? error,
    bool? hasActiveSubscription,
    String? selectedPlanId,
    Map<String, dynamic>? checkoutSession,
  }) {
    return PaymentState(
      subscriptionPlans: subscriptionPlans ?? this.subscriptionPlans,
      superlikePacks: superlikePacks ?? this.superlikePacks,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      error: error ?? this.error,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      checkoutSession: checkoutSession ?? this.checkoutSession,
    );
  }
}

/// Payment notifier
class PaymentNotifier extends StateNotifier<PaymentState> {
  final GetSubscriptionPlansUseCase _getSubscriptionPlansUseCase;
  final PurchaseSubscriptionUseCase _purchaseSubscriptionUseCase;
  final CancelSubscriptionUseCase _cancelSubscriptionUseCase;
  final RestorePurchasesUseCase _restorePurchasesUseCase;
  final ValidateReceiptUseCase _validateReceiptUseCase;
  final GetSuperlikePacksUseCase _getSuperlikePacksUseCase;
  final GetSubscriptionStatusUseCase _getSubscriptionStatusUseCase;
  final CreateStripeCheckoutUseCase _createStripeCheckoutUseCase;

  PaymentNotifier({
    required GetSubscriptionPlansUseCase getSubscriptionPlansUseCase,
    required PurchaseSubscriptionUseCase purchaseSubscriptionUseCase,
    required CancelSubscriptionUseCase cancelSubscriptionUseCase,
    required RestorePurchasesUseCase restorePurchasesUseCase,
    required ValidateReceiptUseCase validateReceiptUseCase,
    required GetSuperlikePacksUseCase getSuperlikePacksUseCase,
    required GetSubscriptionStatusUseCase getSubscriptionStatusUseCase,
    required CreateStripeCheckoutUseCase createStripeCheckoutUseCase,
  }) : _getSubscriptionPlansUseCase = getSubscriptionPlansUseCase,
       _purchaseSubscriptionUseCase = purchaseSubscriptionUseCase,
       _cancelSubscriptionUseCase = cancelSubscriptionUseCase,
       _restorePurchasesUseCase = restorePurchasesUseCase,
       _validateReceiptUseCase = validateReceiptUseCase,
       _getSuperlikePacksUseCase = getSuperlikePacksUseCase,
       _getSubscriptionStatusUseCase = getSubscriptionStatusUseCase,
       _createStripeCheckoutUseCase = createStripeCheckoutUseCase,
       super(PaymentState());

  /// Load subscription plans
  Future<void> loadSubscriptionPlans() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final plans = await _getSubscriptionPlansUseCase.execute();
      state = state.copyWith(
        subscriptionPlans: plans,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load superlike packs
  Future<void> loadSuperlikePacks() async {
    try {
      final packs = await _getSuperlikePacksUseCase.execute();
      state = state.copyWith(superlikePacks: packs);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load subscription status
  Future<void> loadSubscriptionStatus() async {
    try {
      final status = await _getSubscriptionStatusUseCase.execute();
      final hasActive = status.isActive;
      state = state.copyWith(
        subscriptionStatus: status,
        hasActiveSubscription: hasActive,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Purchase subscription
  Future<SubscriptionStatus?> purchaseSubscription(SubscribeRequest request) async {
    state = state.copyWith(isPurchasing: true, error: null);

    try {
      final subscriptionStatus = await _purchaseSubscriptionUseCase.execute(request);
      final hasActive = subscriptionStatus.isActive;

      state = state.copyWith(
        subscriptionStatus: subscriptionStatus,
        hasActiveSubscription: hasActive,
        isPurchasing: false,
      );

      return subscriptionStatus;
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create Stripe checkout session
  Future<Map<String, dynamic>?> createStripeCheckout(StripeCheckoutRequest request) async {
    state = state.copyWith(isPurchasing: true, error: null);

    try {
      final session = await _createStripeCheckoutUseCase.execute(request);
      state = state.copyWith(
        checkoutSession: session,
        isPurchasing: false,
      );
      return session;
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _cancelSubscriptionUseCase.execute(subscriptionId);
      // Update local state
      state = state.copyWith(hasActiveSubscription: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    state = state.copyWith(isRestoring: true, error: null);

    try {
      final success = await _restorePurchasesUseCase.execute();
      state = state.copyWith(isRestoring: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isRestoring: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Validate receipt
  Future<bool> validateReceipt(String receiptData, String transactionId) async {
    try {
      return await _validateReceiptUseCase.execute(receiptData, transactionId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Select plan
  void selectPlan(String planId) {
    state = state.copyWith(selectedPlanId: planId);
  }

  /// Clear selected plan
  void clearSelectedPlan() {
    state = state.copyWith(selectedPlanId: null);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear checkout session
  void clearCheckoutSession() {
    state = state.copyWith(checkoutSession: null);
  }

  /// Reset payment state
  void reset() {
    state = PaymentState();
  }
}

// Use case providers
final getSubscriptionPlansUseCaseProvider = Provider<GetSubscriptionPlansUseCase>((ref) {
  throw UnimplementedError('GetSubscriptionPlansUseCase must be overridden in the provider scope');
});

final purchaseSubscriptionUseCaseProvider = Provider<PurchaseSubscriptionUseCase>((ref) {
  throw UnimplementedError('PurchaseSubscriptionUseCase must be overridden in the provider scope');
});

final cancelSubscriptionUseCaseProvider = Provider<CancelSubscriptionUseCase>((ref) {
  throw UnimplementedError('CancelSubscriptionUseCase must be overridden in the provider scope');
});

final restorePurchasesUseCaseProvider = Provider<RestorePurchasesUseCase>((ref) {
  throw UnimplementedError('RestorePurchasesUseCase must be overridden in the provider scope');
});

final validateReceiptUseCaseProvider = Provider<ValidateReceiptUseCase>((ref) {
  throw UnimplementedError('ValidateReceiptUseCase must be overridden in the provider scope');
});

final getSuperlikePacksUseCaseProvider = Provider<GetSuperlikePacksUseCase>((ref) {
  throw UnimplementedError('GetSuperlikePacksUseCase must be overridden in the provider scope');
});

final getSubscriptionStatusUseCaseProvider = Provider<GetSubscriptionStatusUseCase>((ref) {
  throw UnimplementedError('GetSubscriptionStatusUseCase must be overridden in the provider scope');
});

final createStripeCheckoutUseCaseProvider = Provider<CreateStripeCheckoutUseCase>((ref) {
  throw UnimplementedError('CreateStripeCheckoutUseCase must be overridden in the provider scope');
});
