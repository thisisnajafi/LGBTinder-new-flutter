import '../../data/repositories/notification_repository.dart';
import '../../data/models/notification.dart';

/// Use Case: GetNotificationsUseCase
/// Handles retrieving notifications for the current user
class GetNotificationsUseCase {
  final NotificationRepository _notificationRepository;

  GetNotificationsUseCase(this._notificationRepository);

  /// Execute get notifications use case
  /// Returns [List<Notification>] with user's notifications
  Future<List<Notification>> execute({
    int? page,
    int? limit,
    String? type,
  }) async {
    try {
      return await _notificationRepository.getNotifications(
        page: page,
        limit: limit,
        type: type,
      );
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
