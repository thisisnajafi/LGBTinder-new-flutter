// Widget: MessageBubble
// Chat message bubble
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/cache/image_cache_service.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../routes/app_router.dart';
import '../../features/chat/utils/chat_gallery_items.dart';
import '../../features/chat/utils/chat_link_detector.dart';
import 'chat_image_viewer.dart';
import 'chat_linked_text.dart';
import 'chat_link_preview_card.dart';
import '../../features/chat/presentation/widgets/voice_message_player.dart';
import 'voice_sending_placeholder.dart';
import '../../core/widgets/optimized_image.dart';
import '../../features/chat/data/models/message_delivery_status.dart';
import '../../features/chat/utils/self_destruct_send.dart';
import '../../features/chat/utils/chat_image_placeholder.dart';
import '../../features/chat/utils/chat_local_media.dart';
import '../../features/chat/utils/chat_video_playback.dart';
import '../../features/chat/utils/chat_image_memory.dart';
import 'chat_bubble_photo.dart';
import 'chat_image_send_overlay.dart';
import 'chat_bubble_meta_row.dart';
import 'chat_reply_quote.dart';
import 'chat_forwarded_header.dart';
import 'chat_video_viewer.dart';

/// Premium-aligned decorations for chat bubbles (PremiumShell + brand gradient).
class MessageBubbleChrome {
  MessageBubbleChrome._();

  static EdgeInsets margin({
    required bool isSent,
    bool isFirstInGroup = true,
    bool isLastInGroup = true,
  }) =>
      EdgeInsets.only(
        left: isSent ? AppSpacing.spacingXXL : AppSpacing.spacingSM,
        right: isSent ? AppSpacing.spacingSM : AppSpacing.spacingXXL,
        top: isFirstInGroup ? AppSpacing.spacingXS : 0,
        bottom: isLastInGroup ? AppSpacing.spacingXS : 0,
      );

  /// Telegram-style tail: sharp outer bottom corner on the last bubble only.
  static BorderRadius radius({
    required bool isSent,
    bool tailed = true,
  }) {
    const corner = Radius.circular(AppRadius.radiusLG);
    if (!tailed) {
      return const BorderRadius.all(corner);
    }
    if (isSent) {
      return const BorderRadius.only(
        topLeft: corner,
        topRight: corner,
        bottomLeft: corner,
        bottomRight: Radius.zero,
      );
    }
    return const BorderRadius.only(
      topLeft: corner,
      topRight: corner,
      bottomLeft: Radius.zero,
      bottomRight: corner,
    );
  }

  static BoxDecoration sent({bool isFailed = false, bool tailed = true}) {
    final borderRadius = radius(isSent: true, tailed: tailed);
    if (isFailed) {
      return BoxDecoration(
        color: AppColors.feedbackError.withValues(alpha: 0.92),
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.feedbackError.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.feedbackError.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    return BoxDecoration(
      gradient: AppColors.brandGradient,
      borderRadius: borderRadius,
      boxShadow: [
        BoxShadow(
          color: AppColors.accentViolet.withValues(alpha: 0.28),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration received({
    required bool isDark,
    bool tailed = true,
  }) =>
      BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: radius(isSent: false, tailed: tailed),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: isDark ? 0.14 : 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration locked({
    required bool isDark,
    bool tailed = true,
  }) =>
      received(isDark: isDark, tailed: tailed);

  static BoxDecoration premiumGate({required bool isDark}) => BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentViolet.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration expired({
    required bool isDark,
    bool tailed = true,
  }) =>
      BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: radius(isSent: false, tailed: tailed),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: isDark ? 0.1 : 0.08),
        ),
      );

  /// Receiver unopened self-destruct: dark card, flame in primary (CHAT-SD-002).
  static BoxDecoration selfDestructUnopened({bool tailed = true}) =>
      BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: radius(isSent: false, tailed: tailed),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.22),
        ),
      );

  /// Caption / timestamp on a sent gradient vs a received card bubble.
  static Color onBubbleMeta({required bool isSent, required bool isDark}) {
    if (isSent) return Colors.white70;
    return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  }
}

/// Chat message bubble widget
/// Displays a single message in the chat
/// Data structure based on API: /api/chat/history
///
/// Enter motion for new rows lives on ChatMessageListTile
/// (ChatMessageEnterAnimation, CHAT-ANIM-001 / CHAT-ANIM-002)
/// so history loads stay still.
class MessageBubble extends ConsumerWidget {
  final String message;
  final bool isSent;
  final DateTime? timestamp;
  final bool isRead;
  final bool isDelivered;
  final bool isEdited;
  final MessageDeliveryStatus deliveryStatus;
  final VoidCallback? onRetry;
  final String? messageType; // text, image, video, voice, disappearing_image, disappearing_video
  final String? mediaUrl;
  final int? mediaDuration; // For voice/video messages
  final int? remainingSeconds; // For disappearing messages
  /// Chosen view window (5/10/30/60) shown on the sender bubble.
  final int? expiresInSeconds;
  /// When true (free user, message from non-match): show blurred "You have a new message" placeholder.
  final bool isLocked;
  final bool isBlurred;
  final Map<String, dynamic>? profileCard;
  final String? heroTag;
  final int messageId;
  final bool isExpired;
  final DateTime? viewedAt;
  final VoidCallback? onSelfDestructTap;
  final String? replyToName;
  final String? replyToPreview;
  final VoidCallback? onReplyQuoteTap;
  final String? forwardedFromName;
  final bool isForwarded;
  final String? clientId;
  final String? placeholderDataUri;
  final String? mediaThumbnailUrl;
  final int? mediaWidth;
  final int? mediaHeight;
  final VoidCallback? onImageTap;
  final VoidCallback? onVideoTap;
  final VoidCallback? onVoiceListened;
  /// Sharp outer corner (Telegram tail) only on the last bubble in a run.
  final bool isLastInGroup;
  final bool isFirstInGroup;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.isEdited = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.onRetry,
    this.messageType = 'text',
    this.mediaUrl,
    this.mediaDuration,
    this.remainingSeconds,
    this.expiresInSeconds,
    this.isLocked = false,
    this.isBlurred = false,
    this.profileCard,
    this.heroTag,
    this.messageId = 0,
    this.isExpired = false,
    this.viewedAt,
    this.onSelfDestructTap,
    this.replyToName,
    this.replyToPreview,
    this.onReplyQuoteTap,
    this.forwardedFromName,
    this.isForwarded = false,
    this.clientId,
    this.placeholderDataUri,
    this.mediaThumbnailUrl,
    this.mediaWidth,
    this.mediaHeight,
    this.onImageTap,
    this.onVideoTap,
    this.onVoiceListened,
    this.isLastInGroup = true,
    this.isFirstInGroup = true,
  });

  bool get _isDisappearingType =>
      messageType == 'disappearing_image' ||
      messageType == 'disappearing_video' ||
      messageType == 'self_destruct';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tailed = isLastInGroup;
    final bubbleMargin = MessageBubbleChrome.margin(
      isSent: isSent,
      isFirstInGroup: isFirstInGroup,
      isLastInGroup: isLastInGroup,
    );

    // Locked message: free user received message from non-match (e.g. superlike or ex-match)
    if (isLocked && !isSent) {
      return _LockedIncomingPlaceholder(
        margin: bubbleMargin,
        isDark: isDark,
        tailed: tailed,
        timestamp: timestamp,
      );
    }

    // Premium history gate (static overlay — no BackdropFilter blur)
    if (isBlurred && !isSent) {
      return _PremiumHistoryGate(
        isDark: isDark,
        isFirstInGroup: isFirstInGroup,
        isLastInGroup: isLastInGroup,
        timestamp: timestamp,
      );
    }

    if (messageType == 'profile_link' && profileCard != null) {
      return _ProfileLinkBubble(
        card: profileCard!,
        isSent: isSent,
        timestamp: timestamp,
        isRead: isRead,
        isDelivered: isDelivered,
        deliveryStatus: deliveryStatus,
        messageId: messageId,
        onRetry: onRetry,
        isDark: isDark,
        isFirstInGroup: isFirstInGroup,
        isLastInGroup: isLastInGroup,
      );
    }

    // Self-destruct / disappearing photo states (CHAT-SD-002 / CHAT-SD-004)
    if (_isDisappearingType && !isLocked) {
      final timerElapsed =
          remainingSeconds != null && remainingSeconds! <= 0;
      final showExpired = isExpired || timerElapsed;
      final isOpened = viewedAt != null;
      final canOpen = !isSent && !isOpened && onSelfDestructTap != null;
      final switchDuration = AppAnimations.animationsEnabled(context)
          ? AppAnimations.receiptTick
          : Duration.zero;

      return AnimatedSwitcher(
        duration: switchDuration,
        switchInCurve: AppAnimations.curveDefault,
        switchOutCurve: AppAnimations.curveDefault,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: showExpired
            ? _SelfDestructExpiredBubble(
                key: ValueKey('sd-expired-$messageId'),
                isSent: isSent,
                isDark: isDark,
                viewed: isOpened,
                timestamp: timestamp,
                isRead: isRead,
                isDelivered: isDelivered,
                deliveryStatus: deliveryStatus,
                messageId: messageId,
                onRetry: onRetry,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
              )
            : _SelfDestructPreviewBubble(
                key: ValueKey('sd-preview-$messageId'),
                isSent: isSent,
                isDark: isDark,
                canOpen: canOpen,
                isOpened: isOpened,
                remainingSeconds: remainingSeconds,
                expiresInSeconds: expiresInSeconds,
                onTap: onSelfDestructTap,
                timestamp: timestamp,
                isRead: isRead,
                isDelivered: isDelivered,
                deliveryStatus: deliveryStatus,
                messageId: messageId,
                onRetry: onRetry,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
              ),
      );
    }

    // Sticker messages: no bubble background, 120×120, tap to expand.
    if (messageType == 'sticker' && mediaUrl != null && !isLocked) {
      return _StickerBubble(
        imageUrl: mediaUrl!,
        isSent: isSent,
        timestamp: timestamp,
        isRead: isRead,
        isDelivered: isDelivered,
        isEdited: isEdited,
        deliveryStatus: deliveryStatus,
        messageId: messageId,
        onRetry: onRetry,
        isDark: isDark,
      );
    }

    final isFailed = deliveryStatus == MessageDeliveryStatus.failed;
    final quotePreview = replyToPreview?.trim() ?? '';
    final showReplyQuote = quotePreview.isNotEmpty ||
        (replyToName != null && replyToName!.trim().isNotEmpty);
    final showForwarded = isForwarded ||
        (forwardedFromName != null && forwardedFromName!.trim().isNotEmpty);

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: RepaintBoundary(
        child: GestureDetector(
        onTap: isFailed ? onRetry : null,
        child: Container(
        margin: bubbleMargin,
        constraints: BoxConstraints(
          maxWidth: ResponsiveGrid.chatBubbleMaxWidth(context),
        ),
        padding: EdgeInsets.all(AppSpacing.spacingMD),
        decoration: isSent
            ? MessageBubbleChrome.sent(isFailed: isFailed, tailed: tailed)
            : MessageBubbleChrome.received(isDark: isDark, tailed: tailed),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showForwarded)
              ChatForwardedHeader(
                name: forwardedFromName,
                isSent: isSent,
              ),
            if (showReplyQuote)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacingXS),
                child: ChatReplyQuote(
                  name: replyToName,
                  preview: quotePreview.isNotEmpty ? quotePreview : 'Message',
                  isSent: isSent,
                  onTap: onReplyQuoteTap,
                ),
              ),
            if (messageType == 'image' && mediaUrl != null && !isLocked)
              RepaintBoundary(
              child: GestureDetector(
                onTap: deliveryStatus == MessageDeliveryStatus.sending ||
                        deliveryStatus == MessageDeliveryStatus.failed ||
                        ChatLocalMedia.isLocalPath(mediaUrl)
                    ? (isFailed ? onRetry : null)
                    : (onImageTap ??
                        () => ChatImageViewer.open(
                              context,
                              imageUrl: mediaUrl!,
                              heroTag: heroTag ??
                                  ChatGalleryItem.heroTagFor(
                                    messageId: messageId,
                                    clientId: clientId,
                                  ),
                            )),
                child: Hero(
                  tag: heroTag ??
                      ChatGalleryItem.heroTagFor(
                        messageId: messageId,
                        clientId: clientId,
                      ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        children: [
                          ChatBubblePhoto(
                            imageUrl: mediaUrl!,
                            thumbnailUrl: mediaThumbnailUrl,
                            placeholderDataUri: placeholderDataUri,
                            aspectRatio: ChatImagePlaceholder.aspectRatioOf(
                              width: mediaWidth,
                              height: mediaHeight,
                            ),
                          ),
                          if (isSent &&
                              (isFailed ||
                                  deliveryStatus ==
                                      MessageDeliveryStatus.sending))
                            Positioned.fill(
                              child: ChatImageSendOverlay(
                                clientId: clientId,
                                isFailed: isFailed,
                                isSending: deliveryStatus ==
                                    MessageDeliveryStatus.sending,
                                onRetry: onRetry,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              )
            else if (messageType == 'video' && mediaUrl != null)
              Semantics(
                key: const ValueKey('chat_video_thumb'),
                button: true,
                label: 'Play video',
                child: GestureDetector(
                  onTap: isFailed
                      ? onRetry
                      : ChatVideoPlayback.canOpen(
                          mediaUrl: mediaUrl,
                          deliveryStatus: deliveryStatus,
                        )
                          ? (onVideoTap ??
                              () => ChatVideoViewer.open(
                                    context,
                                    videoUrl: mediaUrl!,
                                  ))
                          : null,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                        child: OptimizedImage(
                          imageUrl:
                              (mediaThumbnailUrl != null &&
                                      mediaThumbnailUrl!.isNotEmpty)
                                  ? mediaThumbnailUrl!
                                  : mediaUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          memoryCacheWidth: ChatImageMemory.bubbleDecodePx(
                            logicalWidth: 200,
                            logicalHeight: 200,
                            devicePixelRatio:
                                MediaQuery.devicePixelRatioOf(context),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(AppSpacing.spacingSM),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const AppSvgIcon(
                              assetPath: AppIcons.playCircle,
                              size: 32,
                              color: Colors.white,
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.radiusXS),
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
                  ),
                ),
              )
            else if (messageType == 'voice' &&
                deliveryStatus == MessageDeliveryStatus.sending &&
                (mediaUrl == null || mediaUrl!.isEmpty))
              VoiceSendingPlaceholder(
                durationSeconds: mediaDuration,
                isSent: isSent,
              )
            else if (messageType == 'voice' && mediaUrl != null)
              RepaintBoundary(
                child: VoiceMessagePlayer(
                  mediaUrl: mediaUrl!,
                  durationSeconds: mediaDuration,
                  isSent: isSent,
                  onListened: isSent ? null : onVoiceListened,
                ),
              ),
            if (message.isNotEmpty && messageType == 'text') ...[
              ChatLinkedText(
                text: message,
                style: AppTypography.body.copyWith(
                  color: isSent
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
                linkColor: isSent
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
              if (ChatLinkPreview.enabled &&
                  ChatLinkDetector.firstUrl(message) != null)
                ChatLinkPreviewCard(
                  url: ChatLinkDetector.firstUrl(message)!,
                  isSent: isSent,
                ),
            ],
            if (remainingSeconds != null && remainingSeconds! > 0)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.spacingXS),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.timer,
                      size: 12,
                      color: MessageBubbleChrome.onBubbleMeta(
                        isSent: isSent,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingXS),
                    Text(
                      '${remainingSeconds}s',
                      style: AppTypography.caption.copyWith(
                        color: MessageBubbleChrome.onBubbleMeta(
                          isSent: isSent,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ChatBubbleMetaRow(
              timestamp: timestamp,
              isSent: isSent,
              isEdited: isEdited,
              isRead: isRead,
              isDelivered: isDelivered,
              deliveryStatus: deliveryStatus,
              messageId: messageId,
              onRetry: onRetry,
              color: MessageBubbleChrome.onBubbleMeta(
                isSent: isSent,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Locked incoming placeholder (no live message body).
class _LockedIncomingPlaceholder extends StatelessWidget {
  const _LockedIncomingPlaceholder({
    required this.margin,
    required this.isDark,
    required this.tailed,
    required this.timestamp,
  });

  final EdgeInsets margin;
  final bool isDark;
  final bool tailed;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: margin,
          constraints: BoxConstraints(
            maxWidth: ResponsiveGrid.chatBubbleMaxWidth(context),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingLG,
            vertical: AppSpacing.spacingMD,
          ),
          decoration: MessageBubbleChrome.locked(
            isDark: isDark,
            tailed: tailed,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                assetPath: AppIcons.lock,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You have a new message',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      'Upgrade to read messages from people who aren\'t your match yet',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    ChatBubbleMetaRow(
                      timestamp: timestamp,
                      isSent: false,
                      color: MessageBubbleChrome.onBubbleMeta(
                        isSent: false,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium history gate: static color overlay (no BackdropFilter).
class _PremiumHistoryGate extends StatelessWidget {
  const _PremiumHistoryGate({
    required this.isDark,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.timestamp,
  });

  final bool isDark;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final overlay = (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
        .withValues(alpha: 0.78);

    return RepaintBoundary(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: 'Premium message hidden. Tap to upgrade.',
          button: true,
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.subscriptionPlans),
            child: Container(
              margin: MessageBubbleChrome.margin(
                isSent: false,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
              ),
              padding: const EdgeInsets.all(AppSpacing.spacingMD),
              decoration: MessageBubbleChrome.premiumGate(isDark: isDark),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    child: ColoredBox(
                      color: overlay,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingSM,
                          vertical: AppSpacing.spacingXS,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppSvgIcon(
                              assetPath: AppIcons.lock,
                              size: 20,
                              color: AppColors.accentViolet,
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
                  ChatBubbleMetaRow(
                    timestamp: timestamp,
                    isSent: false,
                    color: MessageBubbleChrome.onBubbleMeta(
                      isSent: false,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerBubble extends StatefulWidget {
  final String imageUrl;
  final bool isSent;
  final DateTime? timestamp;
  final bool isRead;
  final bool isDelivered;
  final bool isEdited;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;
  final bool isDark;

  const _StickerBubble({
    required this.imageUrl,
    required this.isSent,
    this.timestamp,
    required this.isRead,
    this.isDelivered = false,
    this.isEdited = false,
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
            imageProvider: lgbtfinderCachedImageProvider(widget.imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

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
                ChatBubbleMetaRow(
                  timestamp: widget.timestamp,
                  isSent: widget.isSent,
                  isRead: widget.isRead,
                  isDelivered: widget.isDelivered,
                  isEdited: widget.isEdited,
                  deliveryStatus: widget.deliveryStatus,
                  messageId: widget.messageId,
                  onRetry: widget.onRetry,
                  color: MessageBubbleChrome.onBubbleMeta(
                    isSent: widget.isSent,
                    isDark: widget.isDark,
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
  final bool isDelivered;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;
  final bool isDark;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _ProfileLinkBubble({
    required this.card,
    required this.isSent,
    this.timestamp,
    required this.isRead,
    this.isDelivered = false,
    required this.deliveryStatus,
    this.messageId = 0,
    this.onRetry,
    required this.isDark,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
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
        margin: MessageBubbleChrome.margin(
          isSent: isSent,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
        ),
        padding: const EdgeInsets.all(AppSpacing.spacingMD),
        constraints: BoxConstraints(
          maxWidth: ResponsiveGrid.chatBubbleMaxWidth(context, fraction: 0.72),
        ),
        decoration: isSent
            ? MessageBubbleChrome.sent(
                isFailed: deliveryStatus == MessageDeliveryStatus.failed,
                tailed: isLastInGroup,
              )
            : MessageBubbleChrome.received(
                isDark: isDark,
                tailed: isLastInGroup,
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
            ChatBubbleMetaRow(
              timestamp: timestamp,
              isSent: isSent,
              isRead: isRead,
              isDelivered: isDelivered,
              deliveryStatus: deliveryStatus,
              messageId: messageId,
              onRetry: onRetry,
              color: MessageBubbleChrome.onBubbleMeta(
                isSent: isSent,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _SelfDestructPreviewBubble extends StatelessWidget {
  final bool isSent;
  final bool isDark;
  final bool canOpen;
  final bool isOpened;
  final int? remainingSeconds;
  final int? expiresInSeconds;
  final VoidCallback? onTap;
  final DateTime? timestamp;
  final bool isRead;
  final bool isDelivered;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _SelfDestructPreviewBubble({
    super.key,
    required this.isSent,
    required this.isDark,
    required this.canOpen,
    this.isOpened = false,
    this.remainingSeconds,
    this.expiresInSeconds,
    this.onTap,
    this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.messageId = 0,
    this.onRetry,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final receiverDuration = SelfDestructSend.receiverPreviewDurationSeconds(
      expiresInSeconds: expiresInSeconds,
      remainingSeconds: remainingSeconds,
    );
    final label = isSent
        ? SelfDestructSend.senderLabel(openedByPeer: isOpened)
        : SelfDestructSend.receiverUnopenedLabel(receiverDuration);
    final durationSeconds = SelfDestructSend.displayDurationSeconds(
      isSent: isSent,
      openedByPeer: isOpened,
      expiresInSeconds: expiresInSeconds,
      remainingSeconds: remainingSeconds,
    );
    final isReceiverUnopened = !isSent && canOpen;
    final foreground = isSent
        ? Colors.white
        : (isReceiverUnopened
            ? AppColors.textPrimaryDark
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight));
    final flameColor = isReceiverUnopened ? AppColors.primaryLight : foreground;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: durationSeconds != null
            ? '$label, ${SelfDestructSend.formatDuration(durationSeconds)}'
            : label,
        button: canOpen,
        child: GestureDetector(
          onTap: canOpen ? onTap : null,
          child: Container(
            margin: MessageBubbleChrome.margin(
              isSent: isSent,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
            ),
            padding: const EdgeInsets.all(AppSpacing.spacingMD),
            decoration: isSent
                ? MessageBubbleChrome.sent(
                    isFailed: deliveryStatus == MessageDeliveryStatus.failed,
                    tailed: isLastInGroup,
                  )
                : (isReceiverUnopened
                    ? MessageBubbleChrome.selfDestructUnopened(
                        tailed: isLastInGroup,
                      )
                    : MessageBubbleChrome.received(
                        isDark: isDark,
                        tailed: isLastInGroup,
                      )),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SelfDestructFlamePulse(
                      enabled: isReceiverUnopened,
                      child: AppSvgIcon(
                        assetPath: isReceiverUnopened
                            ? AppIcons.flameBold
                            : AppIcons.flame,
                        size: 22,
                        color: flameColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacingSM),
                    Flexible(
                      child: Text(
                        label,
                        style: textTheme.bodyMedium?.copyWith(color: foreground),
                      ),
                    ),
                    if (isSent &&
                        durationSeconds != null &&
                        durationSeconds > 0) ...[
                      const SizedBox(width: AppSpacing.spacingSM),
                      Text(
                        SelfDestructSend.formatDuration(durationSeconds),
                        style: textTheme.labelSmall?.copyWith(color: foreground),
                      ),
                    ],
                  ],
                ),
                ChatBubbleMetaRow(
                  timestamp: timestamp,
                  isSent: isSent,
                  isRead: isRead,
                  isDelivered: isDelivered,
                  deliveryStatus: deliveryStatus,
                  messageId: messageId,
                  onRetry: onRetry,
                  color: isSent
                      ? MessageBubbleChrome.onBubbleMeta(
                          isSent: true,
                          isDark: isDark,
                        )
                      : (isReceiverUnopened
                          ? AppColors.textSecondaryDark
                          : MessageBubbleChrome.onBubbleMeta(
                              isSent: false,
                              isDark: isDark,
                            )),
                ),
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
  final bool viewed;
  final DateTime? timestamp;
  final bool isRead;
  final bool isDelivered;
  final MessageDeliveryStatus deliveryStatus;
  final int messageId;
  final VoidCallback? onRetry;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _SelfDestructExpiredBubble({
    super.key,
    required this.isSent,
    required this.isDark,
    required this.viewed,
    this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.messageId = 0,
    this.onRetry,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final label = SelfDestructSend.expiredLabel(viewed: viewed);

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: label,
        button: false,
        child: Container(
          margin: MessageBubbleChrome.margin(
            isSent: isSent,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
          ),
          padding: const EdgeInsets.all(AppSpacing.spacingMD),
          decoration: MessageBubbleChrome.expired(
            isDark: isDark,
            tailed: isLastInGroup,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              IgnorePointer(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.flame,
                      size: 20,
                      color: muted,
                    ),
                    const SizedBox(width: AppSpacing.spacingSM),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: muted,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
              ChatBubbleMetaRow(
                timestamp: timestamp,
                isSent: isSent,
                isRead: isRead,
                isDelivered: isDelivered,
                deliveryStatus: deliveryStatus,
                messageId: messageId,
                onRetry: onRetry,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle 2s flame pulse on unopened receiver bubbles. Respects Reduce Motion.
class _SelfDestructFlamePulse extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _SelfDestructFlamePulse({
    required this.child,
    required this.enabled,
  });

  @override
  State<_SelfDestructFlamePulse> createState() =>
      _SelfDestructFlamePulseState();
}

class _SelfDestructFlamePulseState extends State<_SelfDestructFlamePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SelfDestructSend.flamePulseDuration,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: SelfDestructSend.flamePulsePeak)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: SelfDestructSend.flamePulsePeak, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _SelfDestructFlamePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final play = widget.enabled && AppAnimations.animationsEnabled(context);
    if (play) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !AppAnimations.animationsEnabled(context)) {
      return widget.child;
    }
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
