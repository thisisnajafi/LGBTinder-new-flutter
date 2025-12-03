import '../../data/repositories/payment_repository.dart';

/// Use Case: ValidateReceiptUseCase
/// Handles receipt validation for purchases
class ValidateReceiptUseCase {
  final PaymentRepository _paymentRepository;

  ValidateReceiptUseCase(this._paymentRepository);

  /// Execute validate receipt use case
  /// Returns [bool] indicating if receipt is valid
  Future<bool> execute(String receiptData, String transactionId) async {
    try {
      return await _paymentRepository.validateReceipt(receiptData, transactionId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
