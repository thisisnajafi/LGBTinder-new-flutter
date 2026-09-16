import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../features/chat/utils/chat_thread_scroll.dart';
import 'chat_date_badge.dart';

/// Resolves the day pill that should stay pinned at the visual top.
class ChatStickyDate {
  ChatStickyDate._();

  static String? labelForChronologicalIndex(
    List<Map<String, dynamic>> timeline,
    int index,
  ) {
    if (timeline.isEmpty) return null;
    final clamped = index.clamp(0, timeline.length - 1);
    for (var i = clamped; i >= 0; i--) {
      if (timeline[i]['kind'] == ChatDateBadgeInserter.kind) {
        final label = timeline[i]['label']?.toString();
        if (label != null && label.isNotEmpty) return label;
      }
    }
    return null;
  }

  static String? labelForVisualIndex(
    List<Map<String, dynamic>> timeline,
    int visualIndex,
  ) {
    final chrono = ChatThreadScroll.chronologicalIndex(
      timeline.length,
      visualIndex,
    );
    return labelForChronologicalIndex(timeline, chrono);
  }

  /// Day shown under the header: the row at the visual top, or the newest
  /// day when a short reverse thread leaves the top of the viewport empty.
  static String? labelAtViewport({
    required List<Map<String, dynamic>> timeline,
    required GlobalKey listKey,
  }) {
    final visual = visualIndexAtViewportTop(listKey);
    if (visual != null) {
      return labelForVisualIndex(timeline, visual);
    }
    if (timeline.isEmpty) return null;
    return labelForChronologicalIndex(timeline, timeline.length - 1);
  }

  static int? visualIndexAtViewportTop(GlobalKey listKey) {
    final context = listKey.currentContext;
    if (context == null) return null;
    final root = context.findRenderObject();
    if (root is! RenderBox || !root.hasSize) return null;

    RenderSliverMultiBoxAdaptor? sliver;
    void visit(RenderObject child) {
      if (sliver != null) return;
      if (child is RenderSliverMultiBoxAdaptor) {
        sliver = child;
        return;
      }
      child.visitChildren(visit);
    }

    visit(root);
    final adaptor = sliver;
    if (adaptor == null) return null;

    final topY = root.localToGlobal(Offset.zero).dy;
    final bottomY = topY + root.size.height;

    RenderBox? child = adaptor.firstChild;
    RenderBox? topMost;
    var minDy = double.infinity;
    while (child != null) {
      final dy = child.localToGlobal(Offset.zero).dy;
      final childBottom = dy + child.size.height;
      final visible = childBottom > topY && dy < bottomY;
      if (visible && dy < minDy) {
        minDy = dy;
        topMost = child;
      }
      child = adaptor.childAfter(child);
    }
    if (topMost == null) return null;
    final parentData = topMost.parentData;
    if (parentData is SliverMultiBoxAdaptorParentData) {
      return parentData.index;
    }
    return adaptor.indexOf(topMost);
  }
}

/// Floating day chip that tracks the messages at the top of a reverse thread.
class ChatStickyDateHeader extends StatefulWidget {
  final ScrollController controller;
  final List<Map<String, dynamic>> timeline;
  final GlobalKey listKey;

  const ChatStickyDateHeader({
    super.key,
    required this.controller,
    required this.timeline,
    required this.listKey,
  });

  @override
  State<ChatStickyDateHeader> createState() => _ChatStickyDateHeaderState();
}

class _ChatStickyDateHeaderState extends State<ChatStickyDateHeader> {
  String? _label;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scheduleSync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(covariant ChatStickyDateHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_scheduleSync);
      widget.controller.addListener(_scheduleSync);
    }
    _scheduleSync();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scheduleSync);
    super.dispose();
  }

  void _scheduleSync() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _sync();
    });
  }

  void _sync() {
    if (!mounted) return;
    final next = ChatStickyDate.labelAtViewport(
      timeline: widget.timeline,
      listKey: widget.listKey,
    );
    if (next == _label) return;
    setState(() => _label = next);
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null || label.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: ChatDateBadge(
            key: const ValueKey('chat-sticky-date'),
            label: label,
          ),
        ),
      ),
    );
  }
}
