import 'chat_timeline_slots.dart';

/// Consecutive same-sender cluster (CHAT-BUBBLE-001).
///
/// The Telegram “tail” is the sharp outer corner on [isLastInGroup] only —
/// not a painted path.
class ChatBubbleGroup {
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const ChatBubbleGroup({
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  bool get tailed => isLastInGroup;

  static const isolated = ChatBubbleGroup();

  @override
  bool operator ==(Object other) {
    return other is ChatBubbleGroup &&
        other.isFirstInGroup == isFirstInGroup &&
        other.isLastInGroup == isLastInGroup;
  }

  @override
  int get hashCode => Object.hash(isFirstInGroup, isLastInGroup);
}

class ChatBubbleGrouping {
  ChatBubbleGrouping._();

  static bool _sameRun(ChatTimelineSlot a, ChatTimelineSlot b) {
    return a.kind == ChatTimelineSlotKind.message &&
        b.kind == ChatTimelineSlotKind.message &&
        a.isSent == b.isSent;
  }

  /// Chronological slots (oldest → newest). Keys match [ChatTimelineSlot.key].
  static Map<String, ChatBubbleGroup> fromSlots(List<ChatTimelineSlot> slots) {
    final out = <String, ChatBubbleGroup>{};
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if (slot.kind != ChatTimelineSlotKind.message) continue;
      final prev = i > 0 ? slots[i - 1] : null;
      final next = i + 1 < slots.length ? slots[i + 1] : null;
      out[slot.key] = ChatBubbleGroup(
        isFirstInGroup: prev == null || !_sameRun(prev, slot),
        isLastInGroup: next == null || !_sameRun(slot, next),
      );
    }
    return out;
  }
}
