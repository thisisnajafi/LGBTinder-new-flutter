// Widget: MessageBubble
// Chat message bubble
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../images/optimized_image.dart';
import 'message_status_indicator.dart';

/// Chat message bubble widget
/// Displays a single message in the chat
/// Data structure based on API: /api/chat/history
class MessageBubble extends ConsumerWidget {
  final String message;
  final bool isSent;
  final DateTime? timestamp;
  final bool isRead;
  final String? messageType; // text, image, video, voice, disappearing_image, disappearing_video
  final String? mediaUrl;
  final int? mediaDuration; // For voice/video messages
  final int? remainingSeconds; // For disappearing messages
  /// When true (free user, message from non-match): show blurred "You have a new message" placeholder.
  final bool isLocked;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSent,
    this.timestamp,
    this.isRead = false,
    this.messageType = 'text',
    this.mediaUrl,
    this.mediaDuration,
    this.remainingSeconds,
    this.isLocked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Locked message: free user received message from non-match (e.g. superlike or ex-match)
    if (isLocked && !isSent) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: AppSpacing.spacingSM,
            right: AppSpacing.spacingXXL,
            top: AppSpacing.spacingXS,
            bottom: AppSpacing.spacingXS,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingLG,
            vertical: AppSpacing.spacingMD,
          ),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withOpacity(0.9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.radiusMD),
              topRight: Radius.circular(AppRadius.radiusMD),
              bottomRight: Radius.circular(AppRadius.radiusMD),
              bottomLeft: Radius.zero,
            ),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 20,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You have a new message',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      'Upgrade to read messages from people who aren\'t your match yet',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isSent ? AppSpacing.spacingXXL : AppSpacing.spacingSM,
          right: isSent ? AppSpacing.spacingSM : AppSpacing.spacingXXL,
          top: AppSpacing.spacingXS,
          bottom: AppSpacing.spacingXS,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          color: isSent
              ? AppColors.accentPurple
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.radiusMD),
            topRight: Radius.circular(AppRadius.radiusMD),
            bottomLeft: isSent ? Radius.circular(AppRadius.radiusMD) : Radius.zero,
            bottomRight: isSent ? Radius.zero : Radius.circular(AppRadius.radiusMD),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (messageType == 'image' && mediaUrl != null && !isLocked)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                child: OptimizedImage(
                  imageUrl: mediaUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else if (messageType == 'video' && mediaUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    child: OptimizedImage(
                      imageUrl: mediaUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(AppSpacing.spacingSM),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  if (mediaDuration != null)
                    Positioned(
                      bottom: AppSpacing.spacingSM,
                      right: AppSpacing.spacingSM,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingSM,
                          vertical: AppSpacing.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppRadius.radiusXS),
                        ),
                        child: Text(
                          _formatDuration(mediaDuration!),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else if (messageType == 'voice' && mediaUrl != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic,
                    color: isSent ? Colors.white : AppColors.accentPurple,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  if (mediaDuration != null)
                    Text(
                      _formatDuration(mediaDuration!),
                      style: AppTypography.body.copyWith(
                        color: isSent ? Colors.white : AppColors.textPrimaryDark,
                      ),
                    ),
                ],
              ),
            if (message.isNotEmpty && messageType == 'text')
              Text(
                message,
                style: AppTypography.body.copyWith(
                  color: isSent ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            if (remainingSeconds != null && remainingSeconds! > 0)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.spacingXS),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 12,
                      color: isSent ? Colors.white70 : AppColors.textSecondaryDark,
                    ),
                    SizedBox(width: AppSpacing.spacingXS),
                    Text(
                      '${remainingSeconds}s',
                      style: AppTypography.caption.copyWith(
                        color: isSent ? Colors.white70 : AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            if (timestamp != null || isSent)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.spacingXS),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timestamp != null)
                      Text(
                        _formatTime(timestamp!),
                        style: AppTypography.caption.copyWith(
                          color: isSent ? Colors.white70 : AppColors.textSecondaryDark,
                          fontSize: 10,
                        ),
                      ),
                    if (isSent) ...[
                      SizedBox(width: AppSpacing.spacingXS),
                      MessageStatusIndicator(isRead: isRead),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
