import '../../data/repositories/payment_repository.dart';
import '../../data/models/subscription_plan.dart';

/// Use Case: GetSubscriptionPlansUseCase
/// Handles retrieving available subscription plans
class GetSubscriptionPlansUseCase {
  final PaymentRepository _paymentRepository;

  GetSubscriptionPlansUseCase(this._paymentRepository);

  /// Execute get subscription plans use case
  /// Returns [List<SubscriptionPlan>] with all available plans
  Future<List<SubscriptionPlan>> execute() async {
    try {
      return await _paymentRepository.getSubscriptionPlans();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
