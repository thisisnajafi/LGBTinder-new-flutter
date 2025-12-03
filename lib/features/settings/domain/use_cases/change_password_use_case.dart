import '../../data/repositories/settings_repository.dart';

/// Use Case: ChangePasswordUseCase
/// Handles password change operations
class ChangePasswordUseCase {
  final SettingsRepository _settingsRepository;

  ChangePasswordUseCase(this._settingsRepository);

  /// Execute change password use case
  /// Returns void on successful password change
  Future<void> execute(String currentPassword, String newPassword) async {
    try {
      // Validate password strength
      if (newPassword.length < 8) {
        throw Exception('Password must be at least 8 characters long');
      }

      if (currentPassword == newPassword) {
        throw Exception('New password must be different from current password');
      }

      // Basic password validation (you might want more complex rules)
      final hasUppercase = newPassword.contains(RegExp(r'[A-Z]'));
      final hasLowercase = newPassword.contains(RegExp(r'[a-z]'));
      final hasDigits = newPassword.contains(RegExp(r'[0-9]'));

      if (!hasUppercase || !hasLowercase || !hasDigits) {
        throw Exception('Password must contain uppercase, lowercase, and numeric characters');
      }

      return await _settingsRepository.changePassword(currentPassword, newPassword);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
