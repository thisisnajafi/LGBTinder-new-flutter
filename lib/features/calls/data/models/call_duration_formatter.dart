/// Spoken call length for the hang-up summary card (CALL-UI-003).
///
/// Live copy of the formatter used on the call screen. Do not import the
/// unused `call_timer.dart` widget.
class CallDurationFormatter {
  CallDurationFormatter._();

  static String formatLong(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} $minutes minute${minutes == 1 ? '' : 's'}';
    }
    if (minutes > 0) {
      return '$minutes minute${minutes == 1 ? '' : 's'} $seconds second${seconds == 1 ? '' : 's'}';
    }
    return '$seconds second${seconds == 1 ? '' : 's'}';
  }
}
