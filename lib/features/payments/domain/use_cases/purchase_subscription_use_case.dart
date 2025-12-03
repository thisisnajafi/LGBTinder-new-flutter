import '../../data/repositories/payment_repository.dart';
import '../../data/models/subscription_plan.dart';

/// Use Case: PurchaseSubscriptionUseCase
/// Handles subscription plan purchases
class PurchaseSubscriptionUseCase {
  final PaymentRepository _paymentRepository;

  PurchaseSubscriptionUseCase(this._paymentRepository);

  /// Execute purchase subscription use case
  /// Returns [SubscriptionStatus] with subscription details
  Future<SubscriptionStatus> execute(SubscribeRequest request) async {
    try {
      return await _paymentRepository.subscribeToPlan(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
