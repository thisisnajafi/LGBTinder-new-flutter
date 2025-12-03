import '../../data/repositories/notification_repository.dart';

/// Use Case: MarkAsReadUseCase
/// Handles marking notifications as read
class MarkAsReadUseCase {
  final NotificationRepository _notificationRepository;

  MarkAsReadUseCase(this._notificationRepository);

  /// Execute mark as read use case
  /// Returns void on successful marking
  Future<void> execute(int notificationId) async {
    try {
      return await _notificationRepository.markAsRead(notificationId);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      return await _notificationRepository.markAllAsRead();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
