import '../../domain/services/payment_service.dart';
import '../models/subscription_plan.dart';
import '../models/superlike_pack.dart';

/// Payment repository - wraps PaymentService for use in use cases
class PaymentRepository {
  final PaymentService _paymentService;

  PaymentRepository(this._paymentService);

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
    // TODO: Implement superlike packs retrieval
    // This would typically call a service method
    return [];
  }

  /// Purchase superlike pack
  Future<bool> purchaseSuperlikePack(int packId) async {
    // TODO: Implement superlike pack purchase
    // This would typically call a service method
    return false;
  }
}
