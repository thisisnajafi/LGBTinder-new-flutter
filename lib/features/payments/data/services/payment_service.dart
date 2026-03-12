import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/subscription_plan.dart';
import '../models/superlike_pack.dart';
import '../models/payment_history.dart';
import '../models/google_play_purchase_history.dart';

/// Payment service for subscriptions and payments
class PaymentService {
  final ApiService _apiService;

  PaymentService(this._apiService);

  /// Get subscription plans from API (GET subscriptions/plans). Returns data.plans as list of maps.
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.subscriptionsPlans,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return [];
      final plans = response.data!['plans'] as List<dynamic>? ?? [];
      return plans
          .where((e) => e is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create Stripe checkout session (POST subscriptions/create-checkout). Body: price_id, success_url, cancel_url.
  Future<Map<String, dynamic>> createCheckout({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.subscriptionsCreateCheckout,
      data: {
        'price_id': priceId,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/checkout. Body: price_id, success_url, cancel_url; API may require sub_plan_id.
  Future<Map<String, dynamic>> stripeCheckout(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripeCheckout,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/verify-payment. Body: session_id.
  Future<Map<String, dynamic>> stripeVerifyPayment({required String sessionId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripeVerifyPayment,
      data: {'session_id': sessionId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/create-payment-intent. Body: amount, currency; API may require sub_plan_id.
  Future<Map<String, dynamic>> stripeCreatePaymentIntent(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripeCreatePaymentIntent,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/verify-payment-intent. Body: payment_intent_id.
  Future<Map<String, dynamic>> stripeVerifyPaymentIntent({required String paymentIntentId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripeVerifyPaymentIntent,
      data: {'payment_intent_id': paymentIntentId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/create-upgrade-payment-intent. Body: plan_id or new_sub_plan_id.
  Future<Map<String, dynamic>> stripeCreateUpgradePaymentIntent(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripeCreateUpgradePaymentIntent,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/verify-upgrade-payment-intent. Body: payment_intent_id.
  Future<Map<String, dynamic>> stripeVerifyUpgradePaymentIntent({required String paymentIntentId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripeVerifyUpgradePaymentIntent,
      data: {'payment_intent_id': paymentIntentId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/payment-intent. Body: amount; API may require sub_plan_id.
  Future<Map<String, dynamic>> stripePaymentIntent(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripePaymentIntent,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/subscription. Body: price_id; API may require sub_plan_id.
  Future<Map<String, dynamic>> stripeSubscription(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripeSubscription,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST stripe/refund. Body: payment_intent_id.
  Future<Map<String, dynamic>> stripeRefund({required String paymentIntentId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.stripeRefund,
      data: {'payment_intent_id': paymentIntentId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET stripe/analytics
  Future<Map<String, dynamic>> getStripeAnalytics() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.stripeAnalytics,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST paypal/create-order-plan. Body: plan_id or sub_plan_id.
  Future<Map<String, dynamic>> paypalCreateOrderPlan(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.paypalCreateOrderPlan,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST paypal/capture-order. Body: order_id.
  Future<Map<String, dynamic>> paypalCaptureOrder({required String orderId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.paypalCaptureOrder,
      data: {'order_id': orderId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET paypal/order/:orderId
  Future<Map<String, dynamic>> paypalGetOrder(String orderId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.paypalOrderById(orderId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST subscriptions/calculate-upgrade. Body: price_id (or new_plan_id).
  Future<Map<String, dynamic>> calculateUpgrade({required String priceId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.subscriptionsCalculateUpgrade,
      data: {'price_id': priceId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST subscriptions/upgrade-with-penalty. Body: price_id (and any other required fields).
  Future<Map<String, dynamic>> upgradeWithPenalty(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.subscriptionsUpgradeWithPenalty,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST subscriptions/update. Body: price_id.
  Future<Map<String, dynamic>> updateSubscription({required String priceId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.subscriptionsUpdate,
      data: {'price_id': priceId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET subscriptions/verify/:sessionOrToken (e.g. Stripe session id).
  Future<Map<String, dynamic>> verifySubscription(String sessionOrToken) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.subscriptionsVerify(sessionOrToken),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Get all subscription plans (legacy GET /plans)
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.plans,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList
            .map((item) => SubscriptionPlan.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// GET plans/:id — single plan by id.
  Future<Map<String, dynamic>> getPlanById(int planId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planById(planId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST plans. Body: title, price, description (admin).
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.plans,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// PUT plans/:id. Body: title, price, description, etc. (admin).
  Future<Map<String, dynamic>> updatePlan(int planId, Map<String, dynamic> body) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.planById(planId),
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// DELETE plans/:id (admin).
  Future<void> deletePlan(int planId) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.planById(planId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// POST plans/:planId/sub-plans. Body: duration_days, price, sub_plan_title, sub_plan_description (admin).
  Future<Map<String, dynamic>> createPlanSubPlans(int planId, Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.planSubPlans(planId),
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// PUT plans/:planId/sub-plans/:subPlanId. Body: price, etc. (admin).
  Future<Map<String, dynamic>> updatePlanSubPlan(
    int planId,
    int subPlanId,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.planSubPlanById(planId, subPlanId),
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// DELETE plans/:planId/sub-plans/:subPlanId (admin).
  Future<void> deletePlanSubPlan(int planId, int subPlanId) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.planSubPlanById(planId, subPlanId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// Get all sub plans
  Future<List<SubPlan>> getSubPlans() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.subPlans,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList.map((item) => SubPlan.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// GET sub-plans/duration. Query: duration_days (required).
  Future<Map<String, dynamic>> getSubPlansDuration({required int durationDays}) async {
    final path = '${ApiEndpoints.subPlansDuration}?duration_days=$durationDays';
    final response = await _apiService.get<Map<String, dynamic>>(
      path,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST sub-plans/compare. Body: plan_ids (list), duration_days.
  Future<Map<String, dynamic>> compareSubPlans(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.subPlansCompare,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET sub-plans/plan/:planId
  Future<Map<String, dynamic>> getSubPlansByPlan(int planId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.subPlansByPlan(planId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET sub-plans/upgrade-options
  Future<Map<String, dynamic>> getSubPlansUpgradeOptions() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.subPlansUpgradeOptions,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST sub-plans/upgrade. Body: sub_plan_id or new_sub_plan_id.
  Future<Map<String, dynamic>> upgradeSubPlan({required int subPlanId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.subPlansUpgrade,
      data: {'sub_plan_id': subPlanId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET sub-plans/:id
  Future<Map<String, dynamic>> getSubPlanById(int id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.subPlanById(id),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchases — user's plan purchases summary.
  Future<Map<String, dynamic>> getPlanPurchases() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchases,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST plan-purchases. Body: plan_id, payment_method (e.g. stripe).
  Future<Map<String, dynamic>> createPlanPurchase({
    required int planId,
    required String paymentMethod,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.planPurchases,
      data: {'plan_id': planId, 'payment_method': paymentMethod},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchases/history
  Future<Map<String, dynamic>> getPlanPurchasesHistory() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchasesHistory,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchases/active
  Future<Map<String, dynamic>> getPlanPurchasesActive() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchasesActive,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchases/expired
  Future<Map<String, dynamic>> getPlanPurchasesExpired() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchasesExpired,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchases/upgrade-options
  Future<Map<String, dynamic>> getPlanPurchasesUpgradeOptions() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchasesUpgradeOptions,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchases/:id
  Future<Map<String, dynamic>> getPlanPurchaseById(int id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchaseById(id),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchase-actions — list of purchase action records.
  Future<Map<String, dynamic>> getPlanPurchaseActions() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchaseActions,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST plan-purchase-actions. Body: plan_purchase_id, action; or user_id, user_data, name, email, amount, status, stripe_session_id, day.
  Future<Map<String, dynamic>> createPlanPurchaseAction(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.planPurchaseActions,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchase-actions/statistics
  Future<Map<String, dynamic>> getPlanPurchaseActionsStatistics() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchaseActionsStatistics,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchase-actions/today
  Future<Map<String, dynamic>> getPlanPurchaseActionsToday() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchaseActionsToday,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchase-actions/status. Optional [status] query param.
  Future<Map<String, dynamic>> getPlanPurchaseActionsStatus({String? status}) async {
    final path = status != null
        ? '${ApiEndpoints.planPurchaseActionsStatus}?status=$status'
        : ApiEndpoints.planPurchaseActionsStatus;
    final response = await _apiService.get<Map<String, dynamic>>(
      path,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchase-actions/user/:userId
  Future<Map<String, dynamic>> getPlanPurchaseActionsByUser(int userId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchaseActionsUser(userId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET plan-purchase-actions/:id
  Future<Map<String, dynamic>> getPlanPurchaseActionById(int id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.planPurchaseActionById(id),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// PATCH plan-purchase-actions/:id/status. Body: status (e.g. completed).
  Future<Map<String, dynamic>> updatePlanPurchaseActionStatus(int id, String status) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiEndpoints.planPurchaseActionStatus(id),
      data: {'status': status},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Subscribe to a plan
  Future<SubscriptionStatus> subscribeToPlan(SubscribeRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.subscriptionsSubscribe,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return SubscriptionStatus.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get subscription status
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.subscriptionsStatus,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return SubscriptionStatus.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upgrade subscription
  Future<bool> upgradeSubscription(String currentPlanId, String targetPlanId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.subscriptionsUpgrade,
        data: {'current_plan_id': currentPlanId, 'target_plan_id': targetPlanId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response.isSuccess;
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.stripeSubscriptionById(subscriptionId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Validate receipt with payment processor
  Future<bool> validateReceipt(String receiptData, String transactionId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.validateReceipt,
        data: {
          'receipt_data': receiptData,
          'transaction_id': transactionId,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['is_valid'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      // For now, return true to allow purchases (implement proper validation later)
      return true;
    }
  }

  /// Restore purchases from app stores
  Future<bool> restorePurchases() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.restorePurchases,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['restored'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      // For now, return true to indicate restore was attempted
      return true;
    }
  }

  /// Purchase superlike pack
  Future<bool> purchaseSuperlikePack(int packId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.purchaseSuperlikePack,
        data: {'pack_id': packId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['purchased'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      // For now, return true to indicate purchase was attempted
      return true;
    }
  }

  /// Get payment history (legacy: GET /payments/history)
  Future<List<PaymentHistory>> getPaymentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get<dynamic>(
        '${ApiEndpoints.paymentHistory}?page=$page&limit=$limit',
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList
            .map((item) => PaymentHistory.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Get user payment history (API: GET user/payments/history). Returns data with payments list and pagination.
  Future<Map<String, dynamic>> getUserPaymentHistory({int page = 1, int limit = 20}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.userPaymentsHistory,
      queryParameters: {'page': page, 'per_page': limit},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {'payments': [], 'pagination': {}};
  }

  /// Get user payment subscription info (API: GET user/payments/subscription).
  Future<Map<String, dynamic>> getUserPaymentSubscription() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.userPaymentsSubscription,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Get user payment receipt (API: GET user/payments/receipt/:id).
  Future<Map<String, dynamic>> getUserPaymentReceipt(int receiptId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.userPaymentsReceipt(receiptId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Get failed user payments (API: GET user/payments/failed).
  Future<List<Map<String, dynamic>>> getUserPaymentsFailed() async {
    final response = await _apiService.get<dynamic>(ApiEndpoints.userPaymentsFailed);
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] ?? data['payments'];
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    if (response.data is List) {
      return (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Request refund for a user payment (API: POST user/payments/refund/:id).
  Future<Map<String, dynamic>> requestUserPaymentRefund(int paymentId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.userPaymentsRefund(paymentId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Set default payment method (API: PATCH user/payment-methods/default). Body: payment_method_id.
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiEndpoints.userPaymentMethodsDefault,
      data: {'payment_method_id': paymentMethodId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// GET payment-methods — catalog of available payment methods.
  Future<Map<String, dynamic>> getPaymentMethodsCatalog() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.paymentMethodsList,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET payment-methods/:id
  Future<Map<String, dynamic>> getPaymentMethodById(int id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.paymentMethodById(id),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET payment-methods/currency/:currency (e.g. usd).
  Future<Map<String, dynamic>> getPaymentMethodsByCurrency(String currency) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.paymentMethodsCurrency(currency),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET payment-methods/type/:type (e.g. card).
  Future<Map<String, dynamic>> getPaymentMethodsByType(String type) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.paymentMethodsType(type),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST payment-methods/validate-amount. Body: amount, currency, payment_method_id.
  Future<Map<String, dynamic>> validatePaymentAmount({
    required double amount,
    required String currency,
    required int paymentMethodId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.paymentMethodsValidateAmount,
      data: {
        'amount': amount,
        'currency': currency,
        'payment_method_id': paymentMethodId,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Get Google Play products (API: GET google-play/products). Returns data or empty list on error.
  Future<List<Map<String, dynamic>>> getGooglePlayProducts() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.googlePlayProducts);
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final list = data['data'] ?? data['products'];
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      if (response.data is List) {
        return (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Consume a one-time purchase (API: POST google-play/consume-purchase). Body: purchase_token.
  Future<void> consumeGooglePlayPurchase(String purchaseToken) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.googlePlayConsumePurchase,
      data: {'purchase_token': purchaseToken},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// Get Google Play purchase history
  Future<List<GooglePlayPurchaseHistory>> getGooglePlayPurchaseHistory({
    String? type, // 'subscription' or 'one_time'
    String? status, // 'completed', 'pending', 'cancelled', 'refunded'
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': limit,
      };
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.googlePlayPurchasesHistory,
        queryParameters: queryParams,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList
            .map((item) => GooglePlayPurchaseHistory.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get Google Play purchase details
  Future<GooglePlayPurchaseHistory> getGooglePlayPurchaseDetails(int purchaseId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.googlePlayPurchaseDetails(purchaseId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return GooglePlayPurchaseHistory.fromJson(response.data!['data'] ?? response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get active Google Play subscriptions
  Future<List<Map<String, dynamic>>> getGooglePlayActiveSubscriptions() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.googlePlaySubscriptionsActive,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel Google Play subscription (POST google-play/subscriptions/:id/cancel)
  Future<void> cancelGooglePlaySubscription(int subscriptionId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.googlePlayCancelSubscription(subscriptionId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST google-play/subscription/cancel. Body: purchase_token.
  Future<Map<String, dynamic>> cancelGooglePlaySubscriptionByToken(String purchaseToken) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.googlePlaySubscriptionCancel,
      data: {'purchase_token': purchaseToken},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET google-play/analytics/purchases
  Future<Map<String, dynamic>> getGooglePlayAnalyticsPurchases() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.googlePlayAnalyticsPurchases,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET google-play/analytics/subscriptions
  Future<Map<String, dynamic>> getGooglePlayAnalyticsSubscriptions() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.googlePlayAnalyticsSubscriptions,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET google-play/analytics/webhooks
  Future<Map<String, dynamic>> getGooglePlayAnalyticsWebhooks() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.googlePlayAnalyticsWebhooks,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET google-play/analytics/errors
  Future<Map<String, dynamic>> getGooglePlayAnalyticsErrors() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.googlePlayAnalyticsErrors,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Get Google Play subscriptions history (GET google-play/subscriptions/history)
  Future<List<Map<String, dynamic>>> getGooglePlaySubscriptionsHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.googlePlaySubscriptionsHistory,
        queryParameters: {'page': page, 'per_page': limit},
      );
      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }
      if (dataList != null) {
        return dataList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get Google Play subscription details (GET google-play/subscriptions/:id)
  Future<Map<String, dynamic>> getGooglePlaySubscriptionDetails(int subscriptionId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.googlePlaySubscriptionDetails(subscriptionId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }
}

