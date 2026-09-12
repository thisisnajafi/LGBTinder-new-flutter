import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_date_time.dart';
import '../../features/chat/data/models/message_delivery_status.dart';
import '../../features/chat/utils/chat_send_retry.dart';
import 'message_status_indicator.dart';

/// Telegram-style HH:mm + outgoing ticks inside the bubble (CHAT-BUBBLE-002).
class ChatBubbleMetaRow extends StatelessWidget {
  static const String editedLabel = 'edited';

  final DateTime? timestamp;
  final bool isSent;
  final bool isEdited;
  final bool isRead;
  final bool isDelivered;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;
  final Color color;

  const ChatBubbleMetaRow({
    super.key,
    this.timestamp,
    required this.isSent,
    this.isEdited = false,
    this.isRead = false,
    this.isDelivered = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.messageId = 0,
    this.onRetry,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (timestamp == null && !isSent && !isEdited) {
      return const SizedBox.shrink();
    }
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
        );
    final retryLabel = ChatSendRetry.labelFor(
      deliveryStatus,
      canRetry: onRetry != null,
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.spacingXS),
      child: Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEdited) ...[
                Text(
                  editedLabel,
                  style: style?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: color.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingXS),
              ],
              if (timestamp != null)
                Text(
                  AppDateTime.formatChatTime(timestamp!),
                  style: style,
                ),
              if (isSent) ...[
                const SizedBox(width: AppSpacing.spacingXS),
                MessageStatusIndicator(
                  isRead: isRead,
                  isDelivered: isDelivered,
                  deliveryStatus: deliveryStatus,
                  messageId: messageId,
                  onRetry: onRetry,
                  sentColor: color,
                ),
              ],
            ],
          ),
          if (retryLabel != null)
            Semantics(
              label: retryLabel,
              button: onRetry != null,
              child: GestureDetector(
                onTap: onRetry,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Align(
                    alignment: isSent
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      retryLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.feedbackError,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
