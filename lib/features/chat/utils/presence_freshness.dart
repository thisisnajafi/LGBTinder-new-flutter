/// How long an "Online" label stays valid without a new presence event.
///
/// Matches `UserPresenceService::PRESENCE_TTL_SECONDS` (20). A peer who
/// backgrounds without a successful offline POST still drops to Last seen
/// inside the grace used by RT-008.
class PresenceFreshness {
  PresenceFreshness._();

  static const Duration ttl = Duration(seconds: 20);

  static bool isEffectivelyOnline({
    required bool isOnline,
    DateTime? refreshedAt,
    DateTime? now,
  }) {
    if (!isOnline) return false;
    if (refreshedAt == null) return true;
    final current = now ?? DateTime.now();
    final age = current.difference(refreshedAt);
    if (age.isNegative) return true;
    return age < ttl;
  }
}
