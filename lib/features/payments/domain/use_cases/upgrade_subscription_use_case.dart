import '../../data/repositories/payment_repository.dart';

/// Use Case: UpgradeSubscriptionUseCase
/// Handles upgrading a user's subscription plan
class UpgradeSubscriptionUseCase {
  final PaymentRepository _paymentRepository;

  UpgradeSubscriptionUseCase(this._paymentRepository);

  /// Execute upgrade subscription use case
  /// Returns [bool] indicating success of upgrade
  Future<bool> execute(String currentPlanId, String targetPlanId) async {
    try {
      // This would typically call a backend API to upgrade the subscription
      // For now, we'll simulate the upgrade process
      return await _paymentRepository.upgradeSubscription(currentPlanId, targetPlanId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
