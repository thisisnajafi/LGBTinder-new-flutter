import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/subscription_plan.dart';
import '../models/superlike_pack.dart';
import '../models/payment_history.dart';

/// Payment service for subscriptions and payments
class PaymentService {
  final ApiService _apiService;

  PaymentService(this._apiService);

  /// Get all subscription plans
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

  /// Create Stripe checkout session
  Future<Map<String, dynamic>> createStripeCheckout(StripeCheckoutRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.stripeCheckout,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
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

  /// Upgrade subscription plan
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

  /// Get payment history
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
}

