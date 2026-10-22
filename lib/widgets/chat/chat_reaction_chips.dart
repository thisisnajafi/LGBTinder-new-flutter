import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../features/chat/utils/chat_reaction_summary.dart';

/// Compact reaction pill that overlaps the bottom edge of a bubble.
class ChatReactionChips extends StatefulWidget {
  final Map<String, int> counts;
  final String? mine;
  final bool isSent;

  /// The other person in this 1:1 thread. Used by the long-press list.
  final String peerName;
  final ValueChanged<String>? onTap;

  const ChatReactionChips({
    super.key,
    required this.counts,
    this.mine,
    this.isSent = false,
    this.peerName = '',
    this.onTap,
  });

  @override
  State<ChatReactionChips> createState() => _ChatReactionChipsState();
}

class _ChatReactionChipsState extends State<ChatReactionChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  int _lastTotal = 0;

  @override
  void initState() {
    super.initState();
    _lastTotal = _total;
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.chatReactionPop,
    );
    _scale = Tween<double>(
      begin: AppAnimations.chatReactionPopScaleBegin,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.chatReactionPopCurve,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  int get _total =>
      widget.counts.values.fold<int>(0, (sum, count) => sum + count);

  void _play() {
    if (!mounted) return;
    _controller.duration = AppAnimations.chatReactionPopDuration(context);
    if (_controller.duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(ChatReactionChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _total;
    if (next > _lastTotal) {
      _play();
    }
    _lastTotal = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MapEntry<String, int>> get _ordered {
    return <MapEntry<String, int>>[
      for (final emoji in ChatReactionSummary.allowed)
        if ((widget.counts[emoji] ?? 0) > 0) MapEntry(emoji, widget.counts[emoji]!),
      ...widget.counts.entries.where(
        (e) => !ChatReactionSummary.allowed.contains(e.key) && e.value > 0,
      ),
    ];
  }

  List<String> _namesFor(String emoji, int count) {
    final names = <String>[];
    final mine = widget.mine == emoji;
    if (mine) names.add('You');
    final others = count - (mine ? 1 : 0);
    if (others > 0) {
      final peer = widget.peerName.trim();
      names.add(peer.isEmpty ? 'Them' : peer);
    }
    return names;
  }

  Future<void> _showWho() async {
    final entries = _ordered;
    if (entries.isEmpty || !mounted) return;
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacingLG,
              0,
              AppSpacing.spacingLG,
              AppSpacing.spacingLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.spacingXS,
                    ),
                    child: Row(
                      children: [
                        Text(entry.key, style: theme.textTheme.titleMedium),
                        const SizedBox(width: AppSpacing.spacingMD),
                        Expanded(
                          child: Text(
                            _namesFor(entry.key, entry.value).join(', '),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered;
    if (ordered.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvas = theme.scaffoldBackgroundColor;
    final fill = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final pill = ScaleTransition(
      key: const ValueKey('chat-reaction-pill'),
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: _showWho,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: canvas, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < ordered.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _EmojiBit(
                    emoji: ordered[i].key,
                    count: ordered[i].value,
                    selected: widget.mine == ordered[i].key,
                    onTap: widget.onTap,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return pill;
  }
}

class _EmojiBit extends StatelessWidget {
  final String emoji;
  final int count;
  final bool selected;
  final ValueChanged<String>? onTap;

  const _EmojiBit({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count > 1 ? '$emoji $count' : emoji;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: count > 1 ? 'React $emoji, $count' : 'React $emoji',
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(emoji),
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: AppAnimations.chatReactionPopDuration(context),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            key: ValueKey('chat-reaction-pop-$emoji'),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
