import '../../data/repositories/settings_repository.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/privacy_settings.dart';

/// Use Case: UpdateSettingsUseCase
/// Handles updating user settings and privacy settings
class UpdateSettingsUseCase {
  final SettingsRepository _settingsRepository;

  UpdateSettingsUseCase(this._settingsRepository);

  /// Execute update user settings use case
  /// Returns [UserSettings] with updated settings
  Future<UserSettings> updateUserSettings(UpdateSettingsRequest request) async {
    try {
      return await _settingsRepository.updateUserSettings(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }

  /// Execute update privacy settings use case
  /// Returns [PrivacySettings] with updated privacy configuration
  Future<PrivacySettings> updatePrivacySettings(UpdatePrivacySettingsRequest request) async {
    try {
      return await _settingsRepository.updatePrivacySettings(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
