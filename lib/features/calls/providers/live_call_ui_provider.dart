import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/live_call_ui_state.dart';

final liveCallUiProvider =
    StateNotifierProvider<LiveCallUiNotifier, LiveCallUiState>((ref) {
  return LiveCallUiNotifier();
});

final callTimerProvider = Provider<Duration>((ref) {
  return ref.watch(liveCallUiProvider.select((state) => state.duration));
});

final isMutedProvider = Provider<bool>((ref) {
  return ref.watch(liveCallUiProvider.select((state) => state.isMuted));
});

final isSpeakerOnProvider = Provider<bool>((ref) {
  return ref.watch(liveCallUiProvider.select((state) => state.isSpeakerOn));
});

final isCameraOnProvider = Provider<bool>((ref) {
  return ref.watch(liveCallUiProvider.select((state) => state.isCameraOn));
});

/// True once the peer has accepted and talk time has started.
final callStatusProvider = Provider<bool>((ref) {
  return ref.watch(liveCallUiProvider.select((state) => state.connected));
});

class LiveCallUiNotifier extends StateNotifier<LiveCallUiState> {
  LiveCallUiNotifier() : super(const LiveCallUiState());

  void reset({bool speakerOn = false}) {
    state = LiveCallUiState(isSpeakerOn: speakerOn);
  }

  void tick() {
    if (!state.connected) return;
    state = state.copyWith(
      duration: state.duration + const Duration(seconds: 1),
    );
  }

  void setConnected(bool connected) {
    if (state.connected == connected) return;
    state = state.copyWith(
      connected: connected,
      duration: connected ? state.duration : Duration.zero,
    );
  }

  void setMuted(bool muted) {
    if (state.isMuted == muted) return;
    state = state.copyWith(isMuted: muted);
  }

  void setSpeakerOn(bool on) {
    if (state.isSpeakerOn == on) return;
    state = state.copyWith(isSpeakerOn: on);
  }

  void setCameraOn(bool on) {
    if (state.isCameraOn == on) return;
    state = state.copyWith(isCameraOn: on);
  }
}
