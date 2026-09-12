import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/widgets/app_list_view.dart';
import '../../features/chat/utils/chat_list_reorder.dart';

/// Implicit 350ms `easeOutCubic` reorder for one messenger row (CHAT-MSG-001).
///
/// Reduce Motion jumps with [Duration.zero]. First list hydrate does not play
/// because the parent passes [previousIndex] == [index].
class ChatListReorderRow extends StatefulWidget {
  final int id;
  final int index;
  final int previousIndex;
  final Widget child;

  const ChatListReorderRow({
    super.key,
    required this.id,
    required this.index,
    required this.previousIndex,
    required this.child,
  });

  @override
  State<ChatListReorderRow> createState() => _ChatListReorderRowState();
}

class _ChatListReorderRowState extends State<ChatListReorderRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double> _dy = const AlwaysStoppedAnimation<double>(0);
  bool _didInitialPlay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.chatListReorder,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = AppAnimations.chatListReorderDuration(context);
    if (_didInitialPlay) return;
    _didInitialPlay = true;
    _tryPlay();
  }

  @override
  void didUpdateWidget(ChatListReorderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = AppAnimations.chatListReorderDuration(context);
    if (widget.index != oldWidget.index ||
        widget.previousIndex != oldWidget.previousIndex) {
      _tryPlay();
    }
  }

  void _tryPlay() {
    if (!ChatListReorder.shouldAnimate(
      previousIndex: widget.previousIndex,
      index: widget.index,
    )) {
      return;
    }
    if (!AppAnimations.animationsEnabled(context)) {
      _dy = const AlwaysStoppedAnimation<double>(0);
      _controller.duration = Duration.zero;
      _controller.value = 1;
      return;
    }
    final pixels = ChatListReorder.slidePixels(
      previousIndex: widget.previousIndex,
      index: widget.index,
    );
    _dy = Tween<double>(begin: pixels, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.curveDefault,
      ),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          key: ValueKey('chat-list-reorder-slide-${widget.id}'),
          offset: Offset(0, _dy.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Tracks the last painted id order so rows can slide instead of jumping.
class ChatListReorderList extends StatefulWidget {
  final int itemCount;
  final int Function(int index) itemIdAt;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const ChatListReorderList({
    super.key,
    required this.itemCount,
    required this.itemIdAt,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.padding,
    this.physics,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  @override
  State<ChatListReorderList> createState() => _ChatListReorderListState();
}

class _ChatListReorderListState extends State<ChatListReorderList> {
  List<int> _ids = const [];

  @override
  Widget build(BuildContext context) {
    final nextIds = <int>[
      for (var i = 0; i < widget.itemCount; i++) widget.itemIdAt(i),
    ];
    final previousIds = _ids;
    final firstPaint = previousIds.isEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ids = nextIds;
    });

    return AppListView.separated(
      physics: widget.physics,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      padding: widget.padding,
      itemCount: widget.itemCount,
      separatorBuilder: widget.separatorBuilder,
      itemBuilder: (context, index) {
        final id = nextIds[index];
        final previousIndex =
            firstPaint ? index : previousIds.indexOf(id);
        return ChatListReorderRow(
          key: ValueKey('chat-list-reorder-$id'),
          id: id,
          index: index,
          previousIndex: previousIndex,
          child: widget.itemBuilder(context, index),
        );
      },
    );
  }
}
