import '../services/payment_service.dart';
import '../services/superlike_pack_service.dart';
import '../models/subscription_plan.dart';
import '../models/superlike_pack.dart';

/// Payment repository - wraps PaymentService for use in use cases
class PaymentRepository {
  final PaymentService _paymentService;
  final SuperlikePackService _superlikePackService;

  PaymentRepository(this._paymentService, this._superlikePackService);

  /// Get all subscription plans
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    return await _paymentService.getPlans();
  }

  /// Get all sub plans
  Future<List<SubPlan>> getSubPlans() async {
    return await _paymentService.getSubPlans();
  }

  /// Subscribe to a plan
  Future<SubscriptionStatus> subscribeToPlan(SubscribeRequest request) async {
    return await _paymentService.subscribeToPlan(request);
  }

  /// Get subscription status
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    return await _paymentService.getSubscriptionStatus();
  }

  /// Create Stripe checkout session
  Future<Map<String, dynamic>> createStripeCheckout(StripeCheckoutRequest request) async {
    return await _paymentService.createStripeCheckout(request);
  }

  /// Upgrade subscription
  Future<SubscriptionStatus> upgradeSubscription(int newPlanId) async {
    return await _paymentService.upgradeSubscription(newPlanId);
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    return await _paymentService.cancelSubscription(subscriptionId);
  }

  /// Get superlike packs
  Future<List<SuperlikePack>> getSuperlikePacks() async {
    try {
      return await _superlikePackService.getAvailablePacks();
    } catch (e) {
      rethrow;
    }
  }

  /// Purchase superlike pack
  Future<bool> purchaseSuperlikePack(int packId) async {
    return await _paymentService.purchaseSuperlikePack(packId);
  }

  /// Validate receipt
  Future<bool> validateReceipt(String receiptData, String transactionId) async {
    return await _paymentService.validateReceipt(receiptData, transactionId);
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    return await _paymentService.restorePurchases();
  }

  /// Upgrade subscription
  Future<bool> upgradeSubscription(String currentPlanId, String targetPlanId) async {
    return await _paymentService.upgradeSubscription(currentPlanId, targetPlanId);
  }

  /// Get payment history
  Future<List<PaymentHistory>> getPaymentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    return await _paymentService.getPaymentHistory(page: page, limit: limit);
  }
}
