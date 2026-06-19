// Widget: MessageBubble
// Chat message bubble
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_date_time.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../routes/app_router.dart';
import '../../features/chat/presentation/widgets/chat_upgrade_widgets.dart';
import '../../features/chat/presentation/widgets/voice_message_player.dart';
import 'voice_sending_placeholder.dart';
import '../images/optimized_image.dart';
import '../../features/chat/data/models/message_delivery_status.dart';
import 'message_status_indicator.dart';

/// Chat message bubble widget
/// Displays a single message in the chat
/// Data structure based on API: /api/chat/history
class MessageBubble extends ConsumerWidget {
  final String message;
  final bool isSent;
  final DateTime? timestamp;
  final bool isRead;
  final MessageDeliveryStatus deliveryStatus;
  final VoidCallback? onRetry;
  final String? messageType; // text, image, video, voice, disappearing_image, disappearing_video
  final String? mediaUrl;
  final int? mediaDuration; // For voice/video messages
  final int? remainingSeconds; // For disappearing messages
  /// When true (free user, message from non-match): show blurred "You have a new message" placeholder.
  final bool isLocked;
  final bool isBlurred;
  final Map<String, dynamic>? profileCard;
  final String? heroTag;
  final int messageId;
  final bool isExpired;
  final DateTime? viewedAt;
  final VoidCallback? onSelfDestructTap;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSent,
    this.timestamp,
    this.isRead = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.onRetry,
    this.messageType = 'text',
    this.mediaUrl,
    this.mediaDuration,
    this.remainingSeconds,
    this.isLocked = false,
    this.isBlurred = false,
    this.profileCard,
    this.heroTag,
    this.messageId = 0,
    this.isExpired = false,
    this.viewedAt,
    this.onSelfDestructTap,
  }) : super(key: key);

  bool get _isDisappearingType =>
      messageType == 'disappearing_image' ||
      messageType == 'disappearing_video' ||
      messageType == 'self_destruct';

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
              AppSvgIcon(
                assetPath: AppIcons.lock,
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

    // Premium blur gate (basid — messages beyond visibility limit)
    if (isBlurred && !isSent) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: 'Premium message hidden. Tap to upgrade.',
          button: true,
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.subscriptionPlans),
            child: Container(
              margin: EdgeInsets.only(
                left: AppSpacing.spacingSM,
                right: AppSpacing.spacingXXL,
                top: AppSpacing.spacingXS,
                bottom: AppSpacing.spacingXS,
              ),
              padding: const EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.25),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.lock,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: AppSpacing.spacingSM),
                      Flexible(
                        child: Text(
                          'Upgrade to read older messages',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (messageType == 'profile_link' && profileCard != null) {
      return _ProfileLinkBubble(
        card: profileCard!,
        isSent: isSent,
        timestamp: timestamp,
        isRead: isRead,
        deliveryStatus: deliveryStatus,
        messageId: messageId,
        onRetry: onRetry,
        isDark: isDark,
      );
    }

    // Self-destruct / disappearing photo states
    if (_isDisappearingType && !isLocked) {
      if (isExpired || (remainingSeconds != null && remainingSeconds! <= 0 && viewedAt != null)) {
        return _SelfDestructExpiredBubble(isSent: isSent, isDark: isDark);
      }

      final canOpen = !isSent && viewedAt == null && onSelfDestructTap != null;
      return _SelfDestructPreviewBubble(
        isSent: isSent,
        isDark: isDark,
        canOpen: canOpen,
        remainingSeconds: remainingSeconds,
        onTap: onSelfDestructTap,
        timestamp: timestamp,
        isRead: isRead,
        deliveryStatus: deliveryStatus,
        onRetry: onRetry,
      );
    }

    // Sticker messages: no bubble background, 120×120, tap to expand.
    if (messageType == 'sticker' && mediaUrl != null && !isLocked) {
      return _StickerBubble(
        imageUrl: mediaUrl!,
        isSent: isSent,
        timestamp: timestamp,
        isRead: isRead,
        deliveryStatus: deliveryStatus,
        messageId: messageId,
        onRetry: onRetry,
        isDark: isDark,
      );
    }

    final isFailed = deliveryStatus == MessageDeliveryStatus.failed;
    final sentDecoration = isSent && !isFailed
        ? BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.radiusLG),
              topRight: const Radius.circular(AppRadius.radiusLG),
              bottomLeft: const Radius.circular(AppRadius.radiusLG),
              bottomRight: Radius.zero,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          )
        : BoxDecoration(
            color: isFailed
                ? AppColors.feedbackError.withValues(alpha: 0.85)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.radiusLG),
              topRight: const Radius.circular(AppRadius.radiusLG),
              bottomLeft: const Radius.circular(AppRadius.radiusLG),
              bottomRight: Radius.zero,
            ),
          );

    final receivedDecoration = BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.white.withValues(alpha: 0.82),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.radiusLG),
        topRight: Radius.circular(AppRadius.radiusLG),
        bottomLeft: Radius.zero,
        bottomRight: Radius.circular(AppRadius.radiusLG),
      ),
      border: Border.all(
        color: AppColors.accentViolet.withValues(alpha: 0.12),
      ),
    );

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: isFailed ? onRetry : null,
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
        decoration: isSent ? sentDecoration : receivedDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (messageType == 'image' && mediaUrl != null && !isLocked)
              GestureDetector(
                onTap: () => ChatImageViewer.open(
                  context,
                  imageUrl: mediaUrl!,
                  heroTag: heroTag ?? mediaUrl,
                ),
                child: Hero(
                  tag: heroTag ?? mediaUrl!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    child: OptimizedImage(
                      imageUrl: mediaUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
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
            else if (messageType == 'voice' &&
                deliveryStatus == MessageDeliveryStatus.sending &&
                (mediaUrl == null || mediaUrl!.isEmpty))
              VoiceSendingPlaceholder(
                durationSeconds: mediaDuration,
                isSent: isSent,
              )
            else if (messageType == 'voice' && mediaUrl != null)
              VoiceMessagePlayer(
                mediaUrl: mediaUrl!,
                durationSeconds: mediaDuration,
                isSent: isSent,
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
                      MessageStatusIndicator(
                        isRead: isRead,
                        deliveryStatus: deliveryStatus,
                        messageId: messageId,
                        onRetry: onRetry,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  String _formatTime(DateTime time) => AppDateTime.formatChatTime(time);

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _StickerBubble extends StatefulWidget {
  final String imageUrl;
  final bool isSent;
  final DateTime? timestamp;
  final bool isRead;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;
  final bool isDark;

  const _StickerBubble({
    required this.imageUrl,
    required this.isSent,
    this.timestamp,
    required this.isRead,
    required this.deliveryStatus,
    this.messageId = 0,
    this.onRetry,
    required this.isDark,
  });

  @override
  State<_StickerBubble> createState() => _StickerBubbleState();
}

class _StickerBubbleState extends State<_StickerBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _popAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _popController.value = 1.0;
      } else {
        _popController.forward();
      }
    });
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: CloseButton(color: AppColors.textPrimaryDark),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(widget.imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) => AppDateTime.formatChatTime(time);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: widget.deliveryStatus == MessageDeliveryStatus.failed
            ? widget.onRetry
            : _openFullScreen,
        child: ScaleTransition(
          scale: _popAnimation,
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.isSent ? AppSpacing.spacingXXL : AppSpacing.spacingSM,
              right: widget.isSent ? AppSpacing.spacingSM : AppSpacing.spacingXXL,
              top: AppSpacing.spacingXS,
              bottom: AppSpacing.spacingXS,
            ),
            child: Column(
              crossAxisAlignment:
                  widget.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Sticker message',
                  button: true,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: OptimizedImage(
                      imageUrl: widget.imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (widget.timestamp != null || widget.isSent)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.spacingXS),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.timestamp != null)
                          Text(
                            _formatTime(widget.timestamp!),
                            style: AppTypography.caption.copyWith(
                              color: widget.isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 10,
                            ),
                          ),
                        if (widget.isSent) ...[
                          SizedBox(width: AppSpacing.spacingXS),
                          MessageStatusIndicator(
                            isRead: widget.isRead,
                            deliveryStatus: widget.deliveryStatus,
                            messageId: widget.messageId,
                            onRetry: widget.onRetry,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLinkBubble extends StatelessWidget {
  final Map<String, dynamic> card;
  final bool isSent;
  final DateTime? timestamp;
  final bool isRead;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;
  final bool isDark;

  const _ProfileLinkBubble({
    required this.card,
    required this.isSent,
    this.timestamp,
    required this.isRead,
    required this.deliveryStatus,
    this.messageId = 0,
    this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final userId = card['user_id'];
    final name = card['display_name']?.toString() ?? 'Profile';
    final age = card['age'];
    final avatar = card['avatar_url']?.toString();
    final verified = card['is_verified'] == true;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isSent ? AppSpacing.spacingXXL : AppSpacing.spacingSM,
          right: isSent ? AppSpacing.spacingSM : AppSpacing.spacingXXL,
          top: AppSpacing.spacingXS,
          bottom: AppSpacing.spacingXS,
        ),
        padding: const EdgeInsets.all(AppSpacing.spacingMD),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isSent
              ? AppColors.primaryLight
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarWidget(imageUrl: avatar, radius: 24, fallbackInitial: name),
                const SizedBox(width: AppSpacing.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              age != null ? '$name, $age' : name,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSent
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 4),
                            AppSvgIcon(
                              assetPath: AppIcons.verify,
                              size: 16,
                              color: isSent ? Colors.white : AppColors.accentPurple,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Shared profile',
                        style: AppTypography.caption.copyWith(
                          color: isSent
                              ? Colors.white70
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            Semantics(
              label: 'View profile of $name',
              button: true,
              child: OutlinedButton(
                onPressed: userId != null
                    ? () => context.push(
                          '${AppRoutes.profileDetail}?userId=$userId',
                        )
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSent ? Colors.white : AppColors.primaryLight,
                  side: BorderSide(
                    color: isSent ? Colors.white70 : AppColors.primaryLight,
                  ),
                ),
                child: const Text('View Profile'),
              ),
            ),
            if (timestamp != null || isSent)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.spacingXS),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timestamp != null)
                      Text(
                        _formatProfileTime(timestamp!),
                        style: AppTypography.caption.copyWith(
                          color: isSent ? Colors.white70 : AppColors.textSecondaryDark,
                          fontSize: 10,
                        ),
                      ),
                    if (isSent) ...[
                      const SizedBox(width: AppSpacing.spacingXS),
                      MessageStatusIndicator(
                        isRead: isRead,
                        deliveryStatus: deliveryStatus,
                        messageId: messageId,
                        onRetry: onRetry,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatProfileTime(DateTime time) => AppDateTime.formatChatTime(time);
}

class _SelfDestructPreviewBubble extends StatelessWidget {
  final bool isSent;
  final bool isDark;
  final bool canOpen;
  final int? remainingSeconds;
  final VoidCallback? onTap;
  final DateTime? timestamp;
  final bool isRead;
  final MessageDeliveryStatus deliveryStatus;
  final VoidCallback? onRetry;

  const _SelfDestructPreviewBubble({
    required this.isSent,
    required this.isDark,
    required this.canOpen,
    this.remainingSeconds,
    this.onTap,
    this.timestamp,
    this.isRead = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSent
        ? AppColors.primaryLight
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final label = isSent
        ? 'Self-destruct photo sent'
        : (canOpen ? 'Tap to view photo' : 'Self-destruct photo');

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: label,
        button: canOpen,
        child: GestureDetector(
          onTap: canOpen ? onTap : null,
          child: Container(
            margin: EdgeInsets.only(
              left: isSent ? AppSpacing.spacingXXL : AppSpacing.spacingSM,
              right: isSent ? AppSpacing.spacingSM : AppSpacing.spacingXXL,
              top: AppSpacing.spacingXS,
              bottom: AppSpacing.spacingXS,
            ),
            padding: const EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.timer,
                  size: 22,
                  color: isSent
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
                const SizedBox(width: AppSpacing.spacingSM),
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: isSent
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
                if (remainingSeconds != null && remainingSeconds! > 0) ...[
                  const SizedBox(width: AppSpacing.spacingSM),
                  Text(
                    '${remainingSeconds}s',
                    style: AppTypography.caption.copyWith(
                      color: isSent
                          ? Colors.white70
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelfDestructExpiredBubble extends StatelessWidget {
  final bool isSent;
  final bool isDark;

  const _SelfDestructExpiredBubble({
    required this.isSent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isSent ? AppSpacing.spacingXXL : AppSpacing.spacingSM,
          right: isSent ? AppSpacing.spacingSM : AppSpacing.spacingXXL,
          top: AppSpacing.spacingXS,
          bottom: AppSpacing.spacingXS,
        ),
        padding: const EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(
            color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.timerPause,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.spacingSM),
            Text(
              'Photo expired',
              style: AppTypography.body.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
