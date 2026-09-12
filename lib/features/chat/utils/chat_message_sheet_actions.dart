/// Which rows appear on the message action menu
/// (CHAT-UX-006 / CHAT-ANIM-006 / CHAT-THREAD-007).
class ChatMessageSheetActions {
  ChatMessageSheetActions._();

  static const List<String> reactEmojis = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '👍',
  ];

  static const Duration deleteWindow = Duration(hours: 24);

  /// Backend `ChatMessageEditService::EDIT_WINDOW_HOURS` (do not invent 48h).
  static const Duration editWindow = Duration(hours: 24);

  static bool canCopy(String? text, {String type = 'text'}) {
    if (type != 'text') return false;
    return text != null && text.trim().isNotEmpty;
  }

  static bool canReport({required bool isSent}) => !isSent;

  static bool canDelete({
    required bool isSent,
    required int messageId,
    bool isDeleted = false,
  }) =>
      isSent && messageId > 0 && !isDeleted;

  static bool canDeleteForEveryone({
    required bool isSent,
    required DateTime? createdAt,
    DateTime? now,
  }) {
    if (!isSent || createdAt == null) return false;
    final clock = now ?? DateTime.now();
    return clock.toUtc().difference(createdAt.toUtc()) < deleteWindow;
  }

  static const Set<String> _blockedForwardTypes = {
    'system',
    'disappearing_image',
    'disappearing_video',
    'self_destruct',
    'call',
  };

  static bool canReact({
    required int messageId,
    required bool isExpired,
  }) =>
      messageId > 0 && !isExpired;

  static const Set<String> _blockedPinTypes = {
    'system',
    'call',
    'disappearing_image',
    'disappearing_video',
    'self_destruct',
  };

  static bool canPin({
    required int messageId,
    required String type,
    bool isDeleted = false,
    bool isExpired = false,
    bool isLocked = false,
  }) {
    if (messageId <= 0 || isDeleted || isExpired || isLocked) return false;
    return !_blockedPinTypes.contains(type);
  }

  static bool canForward({
    required int messageId,
    required String type,
    bool isDeleted = false,
    bool isExpired = false,
    bool isLocked = false,
  }) {
    if (messageId <= 0 || isDeleted || isExpired || isLocked) return false;
    return !_blockedForwardTypes.contains(type);
  }

  static bool canEdit({
    required bool isSent,
    required String type,
    required bool isExpired,
    required int messageId,
    DateTime? createdAt,
    DateTime? now,
  }) {
    if (!isSent || type != 'text' || isExpired || messageId <= 0) {
      return false;
    }
    if (createdAt == null) return true;
    return remainingEditTime(createdAt: createdAt, now: now) != null;
  }

  /// Remaining 24h edit window, or null when the window has closed.
  static Duration? remainingEditTime({
    required DateTime? createdAt,
    DateTime? now,
  }) {
    if (createdAt == null) return null;
    final clock = now ?? DateTime.now();
    final elapsed = clock.toUtc().difference(createdAt.toUtc());
    if (elapsed >= editWindow) return null;
    if (elapsed.isNegative) return editWindow;
    return editWindow - elapsed;
  }

  static String formatEditRemaining(Duration remaining) {
    if (remaining.inHours >= 1) return '${remaining.inHours}h left';
    if (remaining.inMinutes >= 1) return '${remaining.inMinutes}m left';
    return '<1m left';
  }

  /// Menu subtitle for the 24h edit window (CHAT-FEAT-004).
  static String? editRemainingLabel({
    DateTime? createdAt,
    DateTime? now,
  }) {
    final remaining = remainingEditTime(createdAt: createdAt, now: now);
    if (remaining == null) return null;
    return formatEditRemaining(remaining);
  }

  static String? editActionSubtitle({
    DateTime? createdAt,
    DateTime? now,
  }) =>
      editRemainingLabel(createdAt: createdAt, now: now);

  static String editingBarTitle({
    DateTime? createdAt,
    DateTime? now,
  }) {
    final remaining = remainingEditTime(createdAt: createdAt, now: now);
    if (remaining == null) return 'Editing';
    return 'Editing · ${formatEditRemaining(remaining)}';
  }
}
