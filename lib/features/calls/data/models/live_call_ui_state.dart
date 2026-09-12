/// Local in-call chrome (mute / speaker / camera / timer / connected).
///
/// Agora remote/network state stays on [AgoraRtcSession]. Duration is not
/// stored on [CallState] for the live screen.
class LiveCallUiState {
  final Duration duration;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOn;
  final bool connected;

  const LiveCallUiState({
    this.duration = Duration.zero,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOn = true,
    this.connected = false,
  });

  LiveCallUiState copyWith({
    Duration? duration,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraOn,
    bool? connected,
  }) {
    return LiveCallUiState(
      duration: duration ?? this.duration,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      connected: connected ?? this.connected,
    );
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
