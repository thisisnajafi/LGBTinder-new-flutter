import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-optimistic-image upload fraction 0.0–1.0 (CHAT-IMG-001).
class ChatImageUploadProgressNotifier extends StateNotifier<Map<String, double>> {
  ChatImageUploadProgressNotifier() : super(const {});

  static const double _minDelta = 0.02;

  void setProgress(String clientId, double progress) {
    if (clientId.isEmpty) return;
    final clamped = progress.clamp(0.0, 1.0);
    final previous = state[clientId];
    if (previous != null &&
        clamped < 1.0 &&
        (clamped - previous).abs() < _minDelta) {
      return;
    }
    if (previous == clamped) return;
    state = {...state, clientId: clamped};
  }

  void clear(String clientId) {
    if (!state.containsKey(clientId)) return;
    final next = Map<String, double>.from(state)..remove(clientId);
    state = next;
  }
}

final chatImageUploadProgressProvider =
    StateNotifierProvider<ChatImageUploadProgressNotifier, Map<String, double>>(
  (ref) => ChatImageUploadProgressNotifier(),
);
