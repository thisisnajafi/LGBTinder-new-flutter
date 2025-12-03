import '../../data/repositories/notification_repository.dart';
import '../../data/models/notification_preferences.dart';

/// Use Case: UpdatePreferencesUseCase
/// Handles updating notification preferences
class UpdatePreferencesUseCase {
  final NotificationRepository _notificationRepository;

  UpdatePreferencesUseCase(this._notificationRepository);

  /// Execute update preferences use case
  /// Returns [NotificationPreferences] with updated preferences
  Future<NotificationPreferences> execute(
    UpdateNotificationPreferencesRequest request,
  ) async {
    try {
      return await _notificationRepository.updatePreferences(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }

  /// Get current notification preferences
  Future<NotificationPreferences> getPreferences() async {
    try {
      return await _notificationRepository.getPreferences();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
