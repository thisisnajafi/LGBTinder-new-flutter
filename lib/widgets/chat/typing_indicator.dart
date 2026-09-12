// Widget: TypingIndicator
// Animated typing indicator
import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/spacing_constants.dart';

/// Three primary-color dots that bounce while the peer is typing
/// (CHAT-THREAD-003).
class TypingIndicator extends StatefulWidget {
  /// Optional peer name, e.g. "Alex is typing…"
  final String? displayName;

  const TypingIndicator({super.key, this.displayName});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 3;

  AnimationController? _controller;
  List<Animation<double>> _bounces = const [];
  bool _started = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = !AppAnimations.animationsEnabled(context);
    if (_reduced) return;
    _startBounce();
  }

  void _startBounce() {
    final controller = AnimationController(
      vsync: this,
      duration: AppAnimations.chatTypingDot,
    );
    _controller = controller;
    final totalMs = AppAnimations.chatTypingDot.inMilliseconds;
    final staggerMs = AppAnimations.chatTypingStagger.inMilliseconds;
    _bounces = List.generate(_dotCount, (i) {
      final start = (staggerMs * i) / totalMs;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0,
            end: -AppAnimations.chatTypingDotBounce,
          ),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -AppAnimations.chatTypingDotBounce,
            end: 0,
          ),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
    controller.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = theme.colorScheme.primary;
    final label = widget.displayName?.trim();
    final showLabel = label != null && label.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: AppText(
              '$label is typing',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(width: AppSpacing.spacingSM),
        ],
        ...List.generate(_dotCount, (index) => _dot(index, dotColor)),
      ],
    );
  }

  Widget _dot(int index, Color color) {
    final circle = Container(
      width: AppAnimations.chatTypingDotSize,
      height: AppAnimations.chatTypingDotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
    final padded = Padding(
      padding: EdgeInsets.only(
        right: index < _dotCount - 1 ? AppSpacing.spacingXS : 0,
      ),
      child: circle,
    );

    if (_reduced || _bounces.isEmpty) {
      return Transform.translate(
        key: ValueKey('chat-typing-dot-$index'),
        offset: Offset.zero,
        child: padded,
      );
    }

    return AnimatedBuilder(
      animation: _bounces[index],
      builder: (context, child) {
        return Transform.translate(
          key: ValueKey('chat-typing-dot-$index'),
          offset: Offset(0, _bounces[index].value),
          child: child,
        );
      },
      child: padded,
    );
  }
}
