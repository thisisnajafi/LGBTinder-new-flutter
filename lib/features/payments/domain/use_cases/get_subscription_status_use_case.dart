import '../../data/repositories/payment_repository.dart';

/// Use case for getting subscription status
class GetSubscriptionStatusUseCase {
  final PaymentRepository _repository;

  GetSubscriptionStatusUseCase(this._repository);

  /// Execute get subscription status use case
  Future<SubscriptionStatus> execute() async {
    try {
      return await _repository.getSubscriptionStatus();
    } catch (e) {
      rethrow;
    }
  }
}
