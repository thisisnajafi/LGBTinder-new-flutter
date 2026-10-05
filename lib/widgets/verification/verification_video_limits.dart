/// Live verification clips must be between 5 and 10 seconds.
class VerificationVideoLimits {
  VerificationVideoLimits._();

  static const Duration minimum = Duration(seconds: 5);
  static const Duration maximum = Duration(seconds: 10);

  static bool canFinish(Duration elapsed) => elapsed >= minimum;

  static bool mustFinish(Duration elapsed) => elapsed >= maximum;

  static String clock(Duration elapsed) {
    final capped = elapsed > maximum ? maximum : elapsed;
    final seconds = capped.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(1)}s';
  }
}
