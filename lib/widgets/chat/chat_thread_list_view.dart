import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/widgets/premium/premium_layout.dart';
import '../../features/chat/utils/chat_thread_scroll.dart';

/// Virtualized reverse chat thread (newest at the visual bottom).
///
/// Keep-alives are off so off-screen [VoiceMessagePlayer]s dispose. A 1000px
/// cache covers about two viewports to avoid jank on long threads.
///
/// **ValueKey policy (PERF-INFRA-021):** pass `ValueKey(slot.key)` /
/// [ChatTimelineSlots.rowKey] — never the builder `index`. Reverse lists
/// reuse indexes when history prepends.
class ChatThreadListView extends StatelessWidget {
  final ScrollController? controller;
  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  const ChatThreadListView({
    super.key,
    this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  /// Reverse-list builder index → chronological storage index (oldest = 0).
  static int chronologicalIndex(int itemCount, int visualIndex) {
    return ChatThreadScroll.chronologicalIndex(itemCount, visualIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      reverse: ChatThreadScroll.reversed,
      physics: AppScroll.forChat(context),
      scrollCacheExtent: const ScrollCacheExtent.pixels(
        AppScroll.chatThreadCacheExtentPixels,
      ),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Public name from PERF-INFRA-021. Same widget as [ChatThreadListView].
typedef ChatListView = ChatThreadListView;
