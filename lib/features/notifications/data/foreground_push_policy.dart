import '../data/models/notification_preferences.dart';

/// Bridges Riverpod notification prefs to the FCM singleton (no Ref).
class ForegroundPushPolicy {
  ForegroundPushPolicy._();

  static NotificationPreferences? preferences;
  static void Function()? bumpUnread;

  static bool shouldSuppress({
    required String type,
    dynamic fromUserId,
  }) {
    final prefs = preferences;
    if (prefs == null) return false;
    return prefs.shouldSuppressForegroundPush(
      type: type,
      fromUserId: fromUserId,
    );
  }
}
