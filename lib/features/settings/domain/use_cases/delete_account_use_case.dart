import '../../data/repositories/settings_repository.dart';

/// Use Case: DeleteAccountUseCase
/// Handles account deletion operations
class DeleteAccountUseCase {
  final SettingsRepository _settingsRepository;

  DeleteAccountUseCase(this._settingsRepository);

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
      // TODO: Implement checks for active subscriptions, pending payments, etc.
      // For now, return true
      return true;
    } catch (e) {
      return false;
    }
  }
}
