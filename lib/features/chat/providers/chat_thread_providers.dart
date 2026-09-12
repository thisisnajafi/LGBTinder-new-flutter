import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/chat_message_enter_gate.dart';
import '../utils/chat_message_index.dart';
import '../utils/chat_thread_local_apply.dart';
import '../utils/chat_timeline_slots.dart';

/// Per-peer timeline + load flags (CHAT-PERF-002 / CHAT-PERF-007).
class ChatThreadMessagesState {
  final List<Map<String, dynamic>> rows;
  final bool isLoading;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final bool hasError;
  final String? errorMessage;

  const ChatThreadMessagesState({
    this.rows = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.hasError = false,
    this.errorMessage,
  });

  ChatThreadMessagesState copyWith({
    List<Map<String, dynamic>>? rows,
    bool? isLoading,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? hasError,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ChatThreadMessagesState(
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      hasError: hasError ?? this.hasError,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatThreadMessagesNotifier extends StateNotifier<ChatThreadMessagesState> {
  ChatThreadMessagesNotifier() : super(const ChatThreadMessagesState());

  final ChatMessageIndex index = ChatMessageIndex();
  final ChatMessageEnterGate enterGate = ChatMessageEnterGate();
  bool _indexDirty = true;

  List<Map<String, dynamic>> get rows => state.rows;

  void ensureIndex() {
    if (!_indexDirty) return;
    index.rebuild(state.rows);
    _indexDirty = false;
  }

  void setRows(List<Map<String, dynamic>> rows) {
    if (identical(state.rows, rows)) return;
    if (ChatThreadLocalApply.sameSnapshot(state.rows, rows)) return;
    _indexDirty = true;
    state = state.copyWith(rows: rows);
  }

  void replaceAt(int i, Map<String, dynamic> next) {
    ensureIndex();
    final copy = List<Map<String, dynamic>>.from(state.rows);
    index.replaceAt(copy, i, next);
    _indexDirty = false;
    state = state.copyWith(rows: copy);
  }

  void mapRows(
    Map<String, dynamic> Function(Map<String, dynamic> row) mapper,
  ) {
    setRows([for (final row in state.rows) mapper(row)]);
  }

  void patch({
    List<Map<String, dynamic>>? rows,
    bool? isLoading,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? hasError,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    if (rows != null) _indexDirty = true;
    final next = state.copyWith(
      rows: rows,
      isLoading: isLoading,
      isLoadingMore: isLoadingMore,
      loadMoreFailed: loadMoreFailed,
      hasError: hasError,
      errorMessage: errorMessage,
      clearErrorMessage: clearErrorMessage,
    );
    if (identical(next.rows, state.rows) &&
        next.isLoading == state.isLoading &&
        next.isLoadingMore == state.isLoadingMore &&
        next.loadMoreFailed == state.loadMoreFailed &&
        next.hasError == state.hasError &&
        next.errorMessage == state.errorMessage) {
      return;
    }
    state = next;
  }

  void clear() {
    index.clear();
    _indexDirty = true;
    state = const ChatThreadMessagesState();
  }
}

/// `messagesProvider(peerUserId)` — list widgets watch this, not ChatPage setState.
final chatThreadMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadMessagesNotifier, ChatThreadMessagesState, int>(
  (ref, peerUserId) => ChatThreadMessagesNotifier(),
);

final messagesProvider = chatThreadMessagesProvider;

/// Identity for one timeline row so tiles can `select` without the list.
class ChatThreadRowId {
  final int peerUserId;
  final String key;

  const ChatThreadRowId(this.peerUserId, this.key);

  @override
  bool operator ==(Object other) =>
      other is ChatThreadRowId &&
      other.peerUserId == peerUserId &&
      other.key == key;

  @override
  int get hashCode => Object.hash(peerUserId, key);

  Map<String, dynamic>? watch(WidgetRef ref) {
    return ref.watch(chatMessageProvider(this));
  }

  Map<String, dynamic>? read(WidgetRef ref) {
    return ChatTimelineSlots.findRow(
      ref.read(chatThreadMessagesProvider(peerUserId)).rows,
      key,
    );
  }
}

/// Select helper so Riverpod compares row **identity**, not Map contents.
class ChatThreadRowView {
  final Map<String, dynamic>? row;

  const ChatThreadRowView(this.row);

  @override
  bool operator ==(Object other) =>
      other is ChatThreadRowView && identical(other.row, row);

  @override
  int get hashCode => identityHashCode(row);
}

/// One timeline row (PERF-INFRA-011). Tiles watch this, not the full thread.
final chatMessageProvider =
    Provider.autoDispose.family<Map<String, dynamic>?, ChatThreadRowId>(
  (ref, id) {
    return ref
        .watch(
          chatThreadMessagesProvider(id.peerUserId).select(
            (s) => ChatThreadRowView(
              ChatTimelineSlots.findRow(s.rows, id.key),
            ),
          ),
        )
        .row;
  },
);

class ChatThreadChrome {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool isEmpty;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  const ChatThreadChrome({
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
    required this.isEmpty,
    required this.isLoadingMore,
    required this.loadMoreFailed,
  });

  @override
  bool operator ==(Object other) {
    return other is ChatThreadChrome &&
        other.isLoading == isLoading &&
        other.hasError == hasError &&
        other.errorMessage == errorMessage &&
        other.isEmpty == isEmpty &&
        other.isLoadingMore == isLoadingMore &&
        other.loadMoreFailed == loadMoreFailed;
  }

  @override
  int get hashCode => Object.hash(
        isLoading,
        hasError,
        errorMessage,
        isEmpty,
        isLoadingMore,
        loadMoreFailed,
      );
}

/// Reply / edit draft for the composer (CHAT-PERF-007).
class ChatComposerState {
  final int? replyMessageId;
  final String? replyText;
  final String? replyName;
  final String? replyType;
  final int? editingMessageId;
  final String? editingPreview;
  final DateTime? editingCreatedAt;

  const ChatComposerState({
    this.replyMessageId,
    this.replyText,
    this.replyName,
    this.replyType,
    this.editingMessageId,
    this.editingPreview,
    this.editingCreatedAt,
  });

  bool get isEditing => editingMessageId != null;
}

class ChatComposerNotifier extends StateNotifier<ChatComposerState> {
  ChatComposerNotifier() : super(const ChatComposerState());

  void beginReply({
    required int messageId,
    required String text,
    required String type,
    required String name,
  }) {
    state = ChatComposerState(
      replyMessageId: messageId,
      replyText: text,
      replyType: type,
      replyName: name,
    );
  }

  void beginEdit({
    required int messageId,
    required String preview,
    DateTime? createdAt,
  }) {
    state = ChatComposerState(
      editingMessageId: messageId,
      editingPreview: preview,
      editingCreatedAt: createdAt,
    );
  }

  void clear() => state = const ChatComposerState();
}

final chatComposerProvider = StateNotifierProvider.autoDispose
    .family<ChatComposerNotifier, ChatComposerState, int>(
  (ref, peerUserId) => ChatComposerNotifier(),
);

/// Jump-FAB / “at latest” slice so scroll does not rebuild bubbles.
class ChatThreadViewport {
  final bool atBottom;
  final bool showFab;
  final int unseenCount;

  const ChatThreadViewport({
    this.atBottom = true,
    this.showFab = false,
    this.unseenCount = 0,
  });

  ChatThreadViewport copyWith({
    bool? atBottom,
    bool? showFab,
    int? unseenCount,
  }) {
    return ChatThreadViewport(
      atBottom: atBottom ?? this.atBottom,
      showFab: showFab ?? this.showFab,
      unseenCount: unseenCount ?? this.unseenCount,
    );
  }
}

class ChatThreadViewportNotifier extends StateNotifier<ChatThreadViewport> {
  ChatThreadViewportNotifier() : super(const ChatThreadViewport());

  void applyScroll({required bool showFab, required bool atBottom}) {
    final unseen = showFab ? state.unseenCount : 0;
    if (state.showFab == showFab &&
        state.atBottom == atBottom &&
        state.unseenCount == unseen) {
      return;
    }
    state = ChatThreadViewport(
      atBottom: atBottom,
      showFab: showFab,
      unseenCount: unseen,
    );
  }

  void incrementUnseen() {
    state = ChatThreadViewport(
      atBottom: false,
      showFab: true,
      unseenCount: state.unseenCount + 1,
    );
  }

  void clearUnseen() {
    if (state.atBottom && !state.showFab && state.unseenCount == 0) return;
    state = const ChatThreadViewport();
  }
}

final chatThreadViewportProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadViewportNotifier, ChatThreadViewport, int>(
  (ref, peerUserId) => ChatThreadViewportNotifier(),
);

final isAtBottomProvider = Provider.autoDispose.family<bool, int>((ref, peerUserId) {
  return ref.watch(chatThreadViewportProvider(peerUserId)).atBottom;
});

/// Bump to play the at-bottom arrival spring (CHAT-ANIM-013).
class ChatArrivalBounceNotifier extends StateNotifier<int> {
  ChatArrivalBounceNotifier() : super(0);

  void play() => state++;
}

final chatArrivalBounceProvider = StateNotifierProvider.autoDispose
    .family<ChatArrivalBounceNotifier, int, int>(
  (ref, peerUserId) => ChatArrivalBounceNotifier(),
);

/// Last successful mark-as-read for an open thread.
class ConversationReadState {
  final DateTime? markedAt;

  const ConversationReadState({this.markedAt});
}

class ConversationReadNotifier extends StateNotifier<ConversationReadState> {
  ConversationReadNotifier() : super(const ConversationReadState());

  void markNow([DateTime? at]) {
    state = ConversationReadState(markedAt: at ?? DateTime.now());
  }
}

final conversationReadStateProvider = StateNotifierProvider.autoDispose
    .family<ConversationReadNotifier, ConversationReadState, int>(
  (ref, peerUserId) => ConversationReadNotifier(),
);

/// Brief wash on the quoted original after a reply jump (CHAT-THREAD-006).
class ChatReplyHighlightNotifier extends StateNotifier<int?> {
  ChatReplyHighlightNotifier() : super(null);

  Timer? _timer;

  void flash(int messageId, {required Duration hold}) {
    if (messageId <= 0) return;
    _timer?.cancel();
    state = messageId;
    if (hold <= Duration.zero) {
      state = null;
      return;
    }
    _timer = Timer(hold, () {
      if (mounted) state = null;
    });
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    if (state != null) state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final chatReplyHighlightProvider = StateNotifierProvider.autoDispose
    .family<ChatReplyHighlightNotifier, int?, int>(
  (ref, peerUserId) => ChatReplyHighlightNotifier(),
);

/// Typing map split out of [ChatState] so heartbeats do not copy chats/messages.
class ChatTypingUsersNotifier extends StateNotifier<Map<int, bool>> {
  ChatTypingUsersNotifier() : super(const {});

  void setTyping(int userId, bool isTyping) {
    if (userId <= 0) return;
    if (isTyping) {
      if (state[userId] == true) return;
      state = {...state, userId: true};
      return;
    }
    if (!state.containsKey(userId)) return;
    final next = Map<int, bool>.from(state)..remove(userId);
    state = next;
  }
}

final chatTypingUsersProvider =
    StateNotifierProvider<ChatTypingUsersNotifier, Map<int, bool>>(
  (ref) => ChatTypingUsersNotifier(),
);

final typingUsersProvider = chatTypingUsersProvider;
