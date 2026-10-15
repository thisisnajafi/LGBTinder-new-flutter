/// Chat "Online" follows `user.status` transitions.
///
/// Heartbeats refresh last_seen on the server and are not broadcast (RT-020).
/// A short local expiry would show Last seen for someone who is still in the
/// app. The offline event, including `presence:expire-stale`, is what switches
/// the label. [ttl] matches `UserPresenceService::PRESENCE_TTL_SECONDS`.
class PresenceFreshness {
  PresenceFreshness._();

  static const Duration ttl = Duration(seconds: 90);

  static bool isEffectivelyOnline({
    required bool isOnline,
    DateTime? refreshedAt,
    DateTime? now,
  }) {
    if (!isOnline) return false;
    // Heartbeat events no longer refresh this stamp. Stay online until the
    // next user.status says otherwise, including a future clock skew.
    if (refreshedAt != null && now != null && refreshedAt.isAfter(now)) {
      return true;
    }
    return true;
  }
}
