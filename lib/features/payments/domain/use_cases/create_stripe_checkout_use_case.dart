import '../../data/repositories/payment_repository.dart';

/// Use case for creating Stripe checkout sessions
class CreateStripeCheckoutUseCase {
  final PaymentRepository _repository;

  CreateStripeCheckoutUseCase(this._repository);

  /// Execute create Stripe checkout use case
  Future<Map<String, dynamic>> execute(StripeCheckoutRequest request) async {
    try {
      return await _repository.createStripeCheckout(request);
    } catch (e) {
      rethrow;
    }
  }
}
