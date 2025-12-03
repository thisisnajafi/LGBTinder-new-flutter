import '../../data/repositories/payment_repository.dart';

/// Use Case: GetPaymentHistoryUseCase
/// Handles retrieving user's payment history
class GetPaymentHistoryUseCase {
  final PaymentRepository _paymentRepository;

  GetPaymentHistoryUseCase(this._paymentRepository);

  /// Execute get payment history use case
  /// Returns [List<PaymentHistory>] of user's payment transactions
  Future<List<PaymentHistory>> execute({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await _paymentRepository.getPaymentHistory(page: page, limit: limit);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
