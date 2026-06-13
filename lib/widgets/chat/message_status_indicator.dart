// Widget: MessageStatusIndicator
// Message read/sent/delivered/sending/failed status
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/data/models/message_delivery_status.dart';

/// Visual delivery state for outbound messages.
enum MessageReadState {
  sending,
  failed,
  sent,
  delivered,
  read,
}

/// Message delivery / read status for sent bubbles.
class MessageStatusIndicator extends ConsumerWidget {
  final bool isRead;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;

  const MessageStatusIndicator({
    Key? key,
    this.isRead = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.messageId = 0,
    this.onRetry,
  }) : super(key: key);

  MessageReadState get _readState {
    if (deliveryStatus == MessageDeliveryStatus.sending ||
        deliveryStatus == MessageDeliveryStatus.queued) {
      return MessageReadState.sending;
    }
    if (deliveryStatus == MessageDeliveryStatus.failed) {
      return MessageReadState.failed;
    }
    if (isRead) return MessageReadState.read;
    if (messageId > 0) return MessageReadState.delivered;
    return MessageReadState.sent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (_readState) {
      case MessageReadState.sending:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        );
      case MessageReadState.failed:
        return Semantics(
          label: 'Retry sending message',
          button: true,
          child: GestureDetector(
            onTap: onRetry,
            child: AppSvgIcon(
              assetPath: AppIcons.refresh,
              size: 16,
              color: AppColors.feedbackError,
            ),
          ),
        );
      case MessageReadState.sent:
        return Semantics(
          label: 'Message sent',
          child: _MessageCheckIcon(
            color: Colors.white70,
            doubleCheck: false,
          ),
        );
      case MessageReadState.delivered:
        return Semantics(
          label: 'Message delivered',
          child: _MessageCheckIcon(
            color: Colors.white70,
            doubleCheck: true,
          ),
        );
      case MessageReadState.read:
        return Semantics(
          label: 'Message read',
          child: _MessageCheckIcon(
            color: AppColors.accentPurple,
            doubleCheck: true,
          ),
        );
    }
  }
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
    return SizedBox(
      width: doubleCheck ? 18 : 14,
      height: 12,
      child: CustomPaint(
        painter: _CheckMarkPainter(
          color: color,
          doubleCheck: doubleCheck,
        ),
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

  static const double _strokeWidth = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawCheck(canvas, paint, Offset.zero, size);

    if (doubleCheck) {
      _drawCheck(canvas, paint, const Offset(4, 0), size);
    }
  }

  void _drawCheck(Canvas canvas, Paint paint, Offset offset, Size size) {
    final path = Path()
      ..moveTo(offset.dx + size.width * 0.05, offset.dy + size.height * 0.55)
      ..lineTo(offset.dx + size.width * 0.28, offset.dy + size.height * 0.82)
      ..lineTo(offset.dx + size.width * 0.72, offset.dy + size.height * 0.22);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckMarkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.doubleCheck != doubleCheck;
  }
}
