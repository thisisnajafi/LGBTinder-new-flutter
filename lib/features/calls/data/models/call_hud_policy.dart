/// When the in-call HUD (header + controls) may auto-hide.
class CallHudPolicy {
  CallHudPolicy._();

  /// Video calls hide chrome after idle once connected. Voice never auto-hides.
  static bool autoHide({
    required bool isVideo,
    required bool connected,
  }) =>
      isVideo && connected;
}
