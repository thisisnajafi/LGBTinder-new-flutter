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
          child: AppSvgIcon(
            assetPath: AppIcons.tickCircle,
            size: 14,
            color: Colors.white70,
          ),
        );
      case MessageReadState.delivered:
        return _DoubleCheckIcon(
          color: Colors.white70,
          semanticLabel: 'Message delivered',
        );
      case MessageReadState.read:
        return _DoubleCheckIcon(
          color: AppColors.accentPurple,
          semanticLabel: 'Message read',
        );
    }
  }
}

class _DoubleCheckIcon extends StatelessWidget {
  final Color color;
  final String semanticLabel;

  const _DoubleCheckIcon({
    required this.color,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: 18,
        height: 14,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              child: AppSvgIcon(
                assetPath: AppIcons.tickCircle,
                size: 12,
                color: color,
              ),
            ),
            Positioned(
              left: 6,
              child: AppSvgIcon(
                assetPath: AppIcons.tickCircle,
                size: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
