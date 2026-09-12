import 'package:intl/intl.dart';

import '../../../core/utils/app_date_time.dart';

/// Last-seen / empty-preview copy for messenger rows (CHAT-MSG-005).
///
/// Uses `intl` (already in pubspec) — no extra timeago package.
class ChatPresenceCopy {
  ChatPresenceCopy._();

  static const String online = 'Online';
  static const String offline = 'Offline';
  static const String activeRecently = 'Active recently';
  static const String noMessagesYet = 'No messages yet';

  static String lastSeenLabel(DateTime lastSeenAt, {DateTime? now}) {
    final local = lastSeenAt.toLocal();
    final current = (now ?? DateTime.now()).toLocal();
    final difference = current.difference(local);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Last seen just now';
    }
    if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    }
    return 'Last seen ${_monthDay(local, current)}';
  }

  static String _monthDay(DateTime local, DateTime current) {
    try {
      return DateFormat.MMMd().format(local);
    } on Object {
      return AppDateTime.formatRelative(local, now: current);
    }
  }

  /// Preview when the conversation has no last-message text.
  static String emptyPreview({
    required bool isOnline,
    DateTime? lastSeenAt,
    DateTime? now,
  }) {
    if (isOnline) return activeRecently;
    if (lastSeenAt == null) return noMessagesYet;
    final local = lastSeenAt.toLocal();
    final current = (now ?? DateTime.now()).toLocal();
    final difference = current.difference(local);
    if (difference.isNegative || difference.inMinutes < 60) {
      return activeRecently;
    }
    return lastSeenLabel(lastSeenAt, now: now);
  }

  static bool hasLastMessage(String? lastMessage) =>
      lastMessage != null && lastMessage.trim().isNotEmpty;
}
