import '../../data/repositories/payment_repository.dart';

/// Use Case: RestorePurchasesUseCase
/// Handles restoring previous purchases (mainly for mobile apps)
class RestorePurchasesUseCase {
  final PaymentRepository _paymentRepository;

  RestorePurchasesUseCase(this._paymentRepository);

  /// Execute restore purchases use case
  /// Returns [bool] indicating success of restore operation
  Future<bool> execute() async {
    try {
      return await _paymentRepository.restorePurchases();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
