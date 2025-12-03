import '../../data/repositories/settings_repository.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/privacy_settings.dart';

/// Use Case: GetSettingsUseCase
/// Handles retrieving user settings and privacy settings
class GetSettingsUseCase {
  final SettingsRepository _settingsRepository;

  GetSettingsUseCase(this._settingsRepository);

  /// Execute get user settings use case
  /// Returns [UserSettings] with user's current settings
  Future<UserSettings> getUserSettings() async {
    try {
      return await _settingsRepository.getUserSettings();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }

  /// Execute get privacy settings use case
  /// Returns [PrivacySettings] with user's privacy configuration
  Future<PrivacySettings> getPrivacySettings() async {
    try {
      return await _settingsRepository.getPrivacySettings();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
