/// Thrown when a call cannot be started (eligibility or API failure).
class CallInitiateException implements Exception {
  final String message;
  final bool upgradeRequired;
  final bool matchRequired;

  const CallInitiateException(
    this.message, {
    this.upgradeRequired = false,
    this.matchRequired = false,
  });

  bool get alreadyInCall {
    final lower = message.toLowerCase();
    return lower.contains('already an active call') ||
        lower.contains('already in a call');
  }

  @override
  String toString() => message;
}
