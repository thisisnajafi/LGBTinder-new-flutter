import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/chat_outbound_queue_service.dart';

/// Which threads currently have SQLite outbox rows (CHAT-OFFLINE-001).
class ChatOutboxUiState {
  const ChatOutboxUiState({
    this.flushing = false,
    this.pendingReceiverIds = const {},
  });

  final bool flushing;
  final Set<int> pendingReceiverIds;

  bool visibleFor(int peerUserId) =>
      flushing && pendingReceiverIds.contains(peerUserId);

  ChatOutboxUiState copyWith({
    bool? flushing,
    Set<int>? pendingReceiverIds,
  }) {
    return ChatOutboxUiState(
      flushing: flushing ?? this.flushing,
      pendingReceiverIds: pendingReceiverIds ?? this.pendingReceiverIds,
    );
  }
}

class ChatOutboxUiNotifier extends StateNotifier<ChatOutboxUiState> {
  ChatOutboxUiNotifier() : super(const ChatOutboxUiState());

  void addReceiver(int receiverId) {
    if (state.pendingReceiverIds.contains(receiverId)) return;
    state = state.copyWith(
      pendingReceiverIds: {...state.pendingReceiverIds, receiverId},
    );
  }

  void sync(
    List<QueuedChatMessage> pending, {
    bool? flushing,
  }) {
    state = ChatOutboxUiState(
      flushing: flushing ?? state.flushing,
      pendingReceiverIds: {
        for (final queued in pending) queued.receiverId,
      },
    );
  }
}

final chatOutboxUiProvider =
    StateNotifierProvider<ChatOutboxUiNotifier, ChatOutboxUiState>(
  (ref) => ChatOutboxUiNotifier(),
);
