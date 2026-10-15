/// Whether the FCM background isolate should call `showCallkitIncoming`.
///
/// A decline or timeout stored for an earlier call must not hide the next
/// one. The permission-dialog guard (RT-012) applies only while this isolate
/// is itself waiting on the system prompt. Home, the lock screen, and a
/// killed process are not that prompt and must still show the banner.
class BackgroundCallKitShow {
  BackgroundCallKitShow._();

  static bool shouldShow({
    required String? callId,
    required Iterable<String> terminalCallIds,
    required bool permissionRequestInFlight,
  }) {
    final id = callId?.trim() ?? '';
    if (id.isEmpty) return false;
    if (terminalCallIds.contains(id)) return false;
    if (permissionRequestInFlight) return false;
    return true;
  }
}
