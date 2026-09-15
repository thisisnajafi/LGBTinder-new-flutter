// Widget: MessageStatusIndicator
// Message read/sent/delivered/sending/failed status
import 'package:flutter/material.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/data/models/message_delivery_status.dart';
import '../../features/chat/utils/chat_send_retry.dart';

/// Visual delivery state for outbound messages.
enum MessageReadState {
  sending,
  failed,
  sent,
  delivered,
  read,
}

/// When to pulse ticks (CHAT-ANIM-008).
class MessageStatusTick {
  MessageStatusTick._();

  static MessageReadState resolve({
    required MessageDeliveryStatus deliveryStatus,
    required bool isRead,
    required bool isDelivered,
  }) {
    if (deliveryStatus == MessageDeliveryStatus.sending ||
        deliveryStatus == MessageDeliveryStatus.queued) {
      return MessageReadState.sending;
    }
    if (deliveryStatus == MessageDeliveryStatus.failed) {
      return MessageReadState.failed;
    }
    if (isRead) return MessageReadState.read;
    if (isDelivered) return MessageReadState.delivered;
    return MessageReadState.sent;
  }

  static int rank(MessageReadState state) {
    switch (state) {
      case MessageReadState.sending:
      case MessageReadState.failed:
        return 0;
      case MessageReadState.sent:
        return 1;
      case MessageReadState.delivered:
        return 2;
      case MessageReadState.read:
        return 3;
    }
  }

  /// Pulse once on sent→delivered, delivered→read, or sent→read.
  static bool shouldPulse(MessageReadState from, MessageReadState to) {
    if (to != MessageReadState.delivered && to != MessageReadState.read) {
      return false;
    }
    return rank(to) > rank(from);
  }
}

/// Message delivery / read status for sent bubbles.
///
/// Ticks sit inline with the timestamp — no circular badge — matching
/// the linear icon stroke used elsewhere in the design system.
class MessageStatusIndicator extends StatefulWidget {
  final bool isRead;
  final bool isDelivered;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;
  final Color? sentColor;
  final Color? readColor;

  const MessageStatusIndicator({
    super.key,
    this.isRead = false,
    this.isDelivered = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.messageId = 0,
    this.onRetry,
    this.sentColor,
    this.readColor,
  });

  @override
  State<MessageStatusIndicator> createState() => _MessageStatusIndicatorState();
}

class _MessageStatusIndicatorState extends State<MessageStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late MessageReadState _state;

  MessageReadState get _resolved => MessageStatusTick.resolve(
        deliveryStatus: widget.deliveryStatus,
        isRead: widget.isRead,
        isDelivered: widget.isDelivered,
      );

  @override
  void initState() {
    super.initState();
    _state = _resolved;
    _pulse = AnimationController(
      vsync: this,
      duration: AppAnimations.chatStatusTickPulse,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: AppAnimations.chatStatusTickScalePeak,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppAnimations.chatStatusTickScalePeak,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulse);
  }

  @override
  void didUpdateWidget(covariant MessageStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _resolved;
    final from = _state;
    _state = next;
    final recycled = oldWidget.messageId != 0 &&
        widget.messageId != 0 &&
        oldWidget.messageId != widget.messageId;
    if (recycled) {
      _pulse.stop();
      _pulse.value = 0;
      return;
    }
    if (MessageStatusTick.shouldPulse(from, next) &&
        AppAnimations.animationsEnabled(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sent = widget.sentColor ?? _MessageStatusColors.sent;
    final read = widget.readColor ?? Theme.of(context).colorScheme.primary;

    Widget child;
    switch (_resolved) {
      case MessageReadState.sending:
        child = Semantics(
          label: widget.deliveryStatus == MessageDeliveryStatus.queued
              ? 'Message queued'
              : 'Sending message',
          child: AppSvgIcon(
            assetPath: MessageStatusIconPaths.sending,
            size: AppTypography.labelSmall.fontSize!,
            color: sent,
          ),
        );
      case MessageReadState.failed:
        child = widget.onRetry == null
            ? const SizedBox.shrink()
            : Semantics(
                label: ChatSendRetry.retryLabel,
                button: true,
                child: GestureDetector(
                  onTap: widget.onRetry,
                  child: AppSvgIcon(
                    assetPath: MessageStatusIconPaths.retry,
                    size: 14,
                    color: AppColors.feedbackError,
                  ),
                ),
              );
      case MessageReadState.sent:
        child = Semantics(
          label: 'Message sent',
          child: _MessageCheckIcon(
            color: sent,
            doubleCheck: false,
          ),
        );
      case MessageReadState.delivered:
        child = Semantics(
          label: 'Message delivered',
          child: _MessageCheckIcon(
            color: sent,
            doubleCheck: true,
          ),
        );
      case MessageReadState.read:
        child = Semantics(
          label: 'Message read',
          child: _MessageCheckIcon(
            color: read,
            doubleCheck: true,
          ),
        );
    }

    if (!AppAnimations.animationsEnabled(context)) {
      return child;
    }

    return ScaleTransition(
      key: const ValueKey('chat-status-tick-scale'),
      scale: _scale,
      child: child,
    );
  }
}

/// Const SVG paths for status ticks (PERF-COMP-MSG-011).
class MessageStatusIconPaths {
  MessageStatusIconPaths._();

  static const String sending = AppIcons.clock;
  static const String retry = AppIcons.refresh;
}

/// Const-friendly tick colors (lerp cannot be a const).
class _MessageStatusColors {
  static final Color sent = Colors.white.withValues(alpha: 0.72);
}

/// WhatsApp-style check marks without circular badges.
class _MessageCheckIcon extends StatelessWidget {
  const _MessageCheckIcon({
    required this.color,
    required this.doubleCheck,
  });

  final Color color;
  final bool doubleCheck;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : AppAnimations.receiptTick;

    return SizedBox(
      width: doubleCheck ? 16 : 11,
      height: 10,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: duration,
        curve: Curves.easeOut,
        builder: (context, animatedColor, child) {
          return RepaintBoundary(
            key: const ValueKey('chat-status-tick-paint'),
            child: CustomPaint(
              painter: _CheckMarkPainter(
                color: animatedColor ?? color,
                doubleCheck: doubleCheck,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  _CheckMarkPainter({
    required this.color,
    required this.doubleCheck,
  });

  final Color color;
  final bool doubleCheck;

  /// Matches linear SVG icons (`stroke-width="1.5"`, round caps).
  static const double _strokeWidth = 1.5;

  static const double _checkWidth = 11;
  static const double _checkHeight = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawCheck(canvas, paint, Offset.zero);

    if (doubleCheck) {
      _drawCheck(canvas, paint, const Offset(5, 0));
    }
  }

  void _drawCheck(Canvas canvas, Paint paint, Offset origin) {
    final path = Path()
      ..moveTo(origin.dx + _checkWidth * 0.12, origin.dy + _checkHeight * 0.52)
      ..lineTo(origin.dx + _checkWidth * 0.38, origin.dy + _checkHeight * 0.82)
      ..lineTo(origin.dx + _checkWidth * 0.88, origin.dy + _checkHeight * 0.18);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckMarkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.doubleCheck != doubleCheck;
  }
}
