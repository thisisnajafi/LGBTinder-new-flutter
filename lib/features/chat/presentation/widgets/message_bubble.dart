import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../models/message.dart';
import '../models/message_attachment.dart';

/// Message bubble widget
/// Displays chat messages with different styles for sent/received messages
class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isSentByCurrentUser;
  final bool showAvatar;
  final String? senderName;
  final String? senderAvatar;
  final VoidCallback? onLongPress;
  final VoidCallback? onAttachmentTap;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSentByCurrentUser,
    this.showAvatar = false,
    this.senderName,
    this.senderAvatar,
    this.onLongPress,
    this.onAttachmentTap,
  }) : super(key: key);

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animation when message is created
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: widget.isSentByCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isSentByCurrentUser && widget.showAvatar) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                backgroundImage: widget.senderAvatar != null
                    ? NetworkImage(widget.senderAvatar!)
                    : null,
                child: widget.senderAvatar == null
                    ? Text(
                        widget.senderName?.substring(0, 1).toUpperCase() ?? '?',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: GestureDetector(
                onLongPress: widget.onLongPress,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isSentByCurrentUser
                        ? AppColors.primaryLight
                        : (isDark ? AppColors.backgroundDark : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: widget.isSentByCurrentUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: widget.isSentByCurrentUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: !widget.isSentByCurrentUser
                        ? Border.all(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content
                      _buildMessageContent(),

                      const SizedBox(height: 4),

                      // Message time and status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatMessageTime(widget.message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isSentByCurrentUser
                                  ? Colors.white.withOpacity(0.7)
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (widget.isSentByCurrentUser) ...[
                            const SizedBox(width: 4),
                            _buildMessageStatus(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    final theme = Theme.of(context);

    switch (widget.message.messageType) {
      case 'image':
        return _buildImageContent();
      case 'video':
        return _buildVideoContent();
      case 'voice':
        return _buildVoiceContent();
      case 'file':
        return _buildFileContent();
      default:
        return Text(
          widget.message.message,
          style: TextStyle(
            color: widget.isSentByCurrentUser
                ? Colors.white
                : theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildImageContent() {
    return GestureDetector(
      onTap: widget.onAttachmentTap,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: widget.message.attachmentUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.message.attachmentUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                )
              : Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_fill,
            color: widget.isSentByCurrentUser ? Colors.white : AppColors.primaryLight,
            size: 32,
          ),
          const SizedBox(width: 8),
          Text(
            'Video',
            style: TextStyle(
              color: widget.isSentByCurrentUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            color: widget.isSentByCurrentUser ? Colors.white : AppColors.primaryLight,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Voice message',
            style: TextStyle(
              color: widget.isSentByCurrentUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file,
            color: widget.isSentByCurrentUser ? Colors.white : AppColors.primaryLight,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.message.message.isNotEmpty ? widget.message.message : 'File attachment',
              style: TextStyle(
                color: widget.isSentByCurrentUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (widget.message.isRead) {
      return const Icon(
        Icons.done_all,
        size: 14,
        color: Colors.white,
      );
    } else {
      return const Icon(
        Icons.done,
        size: 14,
        color: Colors.white,
      );
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
