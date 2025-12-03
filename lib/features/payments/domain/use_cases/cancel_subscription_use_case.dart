import '../../data/repositories/payment_repository.dart';

/// Use Case: CancelSubscriptionUseCase
/// Handles subscription cancellation
class CancelSubscriptionUseCase {
  final PaymentRepository _paymentRepository;

  CancelSubscriptionUseCase(this._paymentRepository);

  /// Execute cancel subscription use case
  /// Returns void on successful cancellation
  Future<void> execute(String subscriptionId) async {
    try {
      return await _paymentRepository.cancelSubscription(subscriptionId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
