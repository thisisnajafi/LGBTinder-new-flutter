import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../../data/repositories/settings_repository.dart';

/// Use Case: DeleteAccountUseCase
/// Handles account deletion operations
class DeleteAccountUseCase {
  final SettingsRepository _settingsRepository;
  final ApiService _apiService;

  DeleteAccountUseCase(this._settingsRepository, this._apiService);

  /// Execute delete account use case
  /// Returns void on successful account deletion
  Future<void> execute(String password, String reason) async {
    try {
      // Validate inputs
      if (password.isEmpty) {
        throw Exception('Password is required to delete account');
      }

      if (reason.isEmpty) {
        throw Exception('Please provide a reason for deleting your account');
      }

      // Additional validation can be added here
      // For example, checking if user has active subscriptions, etc.

      return await _settingsRepository.deleteAccount(password, reason);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }

  /// Check if account can be deleted (e.g., no active subscriptions)
  Future<bool> canDeleteAccount() async {
    try {
      // Check for active subscriptions
      final subscriptionResponse = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.subscriptionsStatus,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (subscriptionResponse.isSuccess && subscriptionResponse.data != null) {
        final subscriptionData = subscriptionResponse.data!;
        final hasActiveSubscription = subscriptionData['has_active_subscription'] as bool? ?? false;
        final hasPendingPayments = subscriptionData['has_pending_payments'] as bool? ?? false;

        // Cannot delete account if there are active subscriptions or pending payments
        if (hasActiveSubscription || hasPendingPayments) {
          return false;
        }
      }

      // Check for any other conditions that might prevent account deletion
      // (e.g., ongoing matches, active support tickets, etc.)
      // For now, only check subscriptions and payments

      return true;
    } catch (e) {
      // If we can't check, err on the side of caution and prevent deletion
      return false;
    }
  }
}
