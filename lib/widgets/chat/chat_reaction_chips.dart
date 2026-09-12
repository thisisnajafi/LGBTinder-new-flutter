import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../features/chat/utils/chat_reaction_summary.dart';

/// Theme-aware reaction chips under a bubble (CHAT-FEAT-003 / CHAT-UX-005).
class ChatReactionChips extends StatelessWidget {
  final Map<String, int> counts;
  final String? mine;
  final bool isSent;
  final ValueChanged<String>? onTap;

  const ChatReactionChips({
    super.key,
    required this.counts,
    this.mine,
    this.isSent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ordered = <MapEntry<String, int>>[
      for (final emoji in ChatReactionSummary.allowed)
        if ((counts[emoji] ?? 0) > 0) MapEntry(emoji, counts[emoji]!),
      ...counts.entries.where(
        (e) => !ChatReactionSummary.allowed.contains(e.key) && e.value > 0,
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.spacingXS,
        left: isSent ? 0 : AppSpacing.spacingLG,
        right: isSent ? AppSpacing.spacingLG : 0,
      ),
      child: Wrap(
        alignment: isSent ? WrapAlignment.end : WrapAlignment.start,
        spacing: AppSpacing.spacingXS,
        runSpacing: AppSpacing.spacingXS,
        children: [
          for (final entry in ordered)
            _Chip(
              key: ValueKey(entry.key),
              emoji: entry.key,
              count: entry.value,
              selected: mine == entry.key,
              isDark: isDark,
              textStyle: theme.textTheme.labelSmall,
              onTap: onTap,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatefulWidget {
  final String emoji;
  final int count;
  final bool selected;
  final bool isDark;
  final TextStyle? textStyle;
  final ValueChanged<String>? onTap;

  const _Chip({
    super.key,
    required this.emoji,
    required this.count,
    required this.selected,
    required this.isDark,
    required this.textStyle,
    required this.onTap,
  });

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.duration = AppAnimations.chatReactionPopDuration(context);
      if (_controller.duration == Duration.zero) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_Chip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count == widget.count) return;
    _controller.duration = AppAnimations.chatReactionPopDuration(context);
    if (_controller.duration == Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = widget.selected
        ? theme.colorScheme.primary
        : (widget.isDark
            ? AppColors.borderMediumDark
            : AppColors.borderMediumLight);
    final fill = widget.selected
        ? theme.colorScheme.primary.withValues(alpha: 0.16)
        : (widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    return Semantics(
      button: widget.onTap != null,
      selected: widget.selected,
      label: 'React ${widget.emoji}, ${widget.count}',
      child: ScaleTransition(
        key: ValueKey('chat-reaction-pop-${widget.emoji}'),
        scale: _scale,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap == null ? null : () => widget.onTap!(widget.emoji),
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingSM,
                  vertical: AppSpacing.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.emoji} ${widget.count}',
                  style: (widget.textStyle ?? theme.textTheme.labelSmall)?.copyWith(
                    color: widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
