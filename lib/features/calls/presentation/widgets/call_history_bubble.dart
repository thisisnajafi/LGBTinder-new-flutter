import 'package:flutter/material.dart';

import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/utils/call_log_labels.dart';
import 'package:lgbtindernew/widgets/chat/chat_system_message.dart';

/// Centered call log row in a chat thread (CHAT-BUBBLE-007 system chrome).
class CallHistoryBubble extends StatelessWidget {
  final Call call;
  final int currentUserId;
  final DateTime? timestamp;
  final VoidCallback? onTap;

  const CallHistoryBubble({
    super.key,
    required this.call,
    required this.currentUserId,
    this.timestamp,
    this.onTap,
  });

  bool get _isVideo => call.isVideoCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isNegative = CallLogLabels.isMissedOrDeclined(
      call: call,
      currentUserId: currentUserId,
    );
    final label = CallLogLabels.title(call: call, currentUserId: currentUserId);
    final textColor = isNegative
        ? AppColors.feedbackError
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final iconPath = isNegative
        ? AppIcons.callMissed
        : (_isVideo ? AppIcons.video : AppIcons.phone);

    return RepaintBoundary(
      child: ChatSystemMessage(
        caption: label,
        iconPath: iconPath,
        color: textColor,
        onTap: onTap,
      ),
    );
  }
}
