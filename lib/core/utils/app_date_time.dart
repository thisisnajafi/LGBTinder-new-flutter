/// UTC-safe parsing and local display formatting for timestamps.
abstract final class AppDateTime {
  /// Parses API / database values and returns the instant in local time.
  static DateTime? parseApi(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is! String) return null;

    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;

    final hasTimezone = trimmed.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed);

    // Server stores UTC; naive strings without offset are treated as UTC.
    if (!hasTimezone && !parsed.isUtc) {
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      ).toLocal();
    }

    return parsed.toLocal();
  }

  static DateTime toLocal(DateTime value) => value.toLocal();

  /// Serializes an instant as UTC ISO-8601 so cache/API round-trips keep the timezone.
  static String toApi(DateTime value) => value.toUtc().toIso8601String();

  /// Relative time in the device timezone, e.g. `Just now`, `3m ago`, `2h ago`.
  static String formatRelative(DateTime dateTime, {DateTime? now}) {
    final local = dateTime.toLocal();
    final difference = (now ?? DateTime.now()).difference(local);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}';
  }

  /// Chat bubble time, e.g. `3:23 PM`.
  static String formatChatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
