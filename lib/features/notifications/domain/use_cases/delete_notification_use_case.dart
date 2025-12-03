import '../../data/repositories/notification_repository.dart';

/// Use Case: DeleteNotificationUseCase
/// Handles deleting notifications
class DeleteNotificationUseCase {
  final NotificationRepository _notificationRepository;

  DeleteNotificationUseCase(this._notificationRepository);

  /// Execute delete notification use case
  /// Returns void on successful deletion
  Future<void> execute(int notificationId) async {
    try {
      return await _notificationRepository.deleteNotification(notificationId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
