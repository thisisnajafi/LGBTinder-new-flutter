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
