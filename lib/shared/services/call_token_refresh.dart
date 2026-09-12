/// When to refresh an Agora RTC token before it expires.
class CallTokenRefresh {
  CallTokenRefresh._();

  /// Backend TTL is 3600s. Refresh this far ahead of [expiresAt].
  static const Duration leadTime = Duration(minutes: 5);

  /// Delay from [now] until a proactive refresh. Zero means refresh now.
  static Duration delayUntilRefresh(DateTime expiresAt, DateTime now) {
    final target = expiresAt.subtract(leadTime);
    final delay = target.difference(now);
    if (delay.isNegative) return Duration.zero;
    return delay;
  }
}

/// Result of [AgoraService.onTokenRefreshRequired].
class CallTokenRefreshResult {
  final String token;
  final DateTime? expiresAt;

  const CallTokenRefreshResult({
    required this.token,
    this.expiresAt,
  });

  bool get hasToken => token.isNotEmpty;
}
