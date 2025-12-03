import '../../data/repositories/payment_repository.dart';

/// Use Case: PurchaseSuperlikePackUseCase
/// Handles purchasing superlike packs
class PurchaseSuperlikePackUseCase {
  final PaymentRepository _paymentRepository;

  PurchaseSuperlikePackUseCase(this._paymentRepository);

  /// Execute purchase superlike pack use case
  /// Returns [bool] indicating success of purchase
  Future<bool> execute(int packId) async {
    try {
      return await _paymentRepository.purchaseSuperlikePack(packId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
