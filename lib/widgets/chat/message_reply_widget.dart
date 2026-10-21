import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';

/// Composer preview of the message being replied to or edited.
///
/// Height animates 0→[AppAnimations.chatReplyPreviewHeight] unless Reduce
/// Motion is on. Close uses [AppIcons.close], never Material [Icons].
class MessageReplyWidget extends StatefulWidget {
  final String? repliedToName;
  final String? repliedToMessage;
  final String? repliedToMessageType;
  final VoidCallback? onCancel;
  final bool isEditing;

  const MessageReplyWidget({
    super.key,
    this.repliedToName,
    this.repliedToMessage,
    this.repliedToMessageType,
    this.onCancel,
    this.isEditing = false,
  });

  @override
  State<MessageReplyWidget> createState() => _MessageReplyWidgetState();
}

class _MessageReplyWidgetState extends State<MessageReplyWidget> {
  String? _name;
  String? _message;
  String? _type;

  bool get _visible =>
      widget.repliedToName != null || widget.repliedToMessage != null;

  @override
  void initState() {
    super.initState();
    _cachePreview();
  }

  @override
  void didUpdateWidget(covariant MessageReplyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visible) {
      _cachePreview();
    }
  }

  void _cachePreview() {
    _name = widget.repliedToName;
    _message = widget.repliedToMessage;
    _type = widget.repliedToMessageType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = AppColors.accentPurple;
    final duration = AppAnimations.chatReplyPreviewDuration(context);

    return ClipRect(
      child: AnimatedContainer(
        key: const ValueKey('chat-reply-preview'),
        duration: duration,
        curve: AppAnimations.curveDefault,
        height: _visible ? AppAnimations.chatReplyPreviewHeight : 0,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: AppAnimations.chatReplyPreviewHeight,
          maxHeight: AppAnimations.chatReplyPreviewHeight,
          child: SizedBox(
            height: AppAnimations.chatReplyPreviewHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacingMD,
                AppSpacing.spacingXS,
                AppSpacing.spacingMD,
                AppSpacing.spacingXS,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        color: borderColor,
                      ),
                      SizedBox(width: AppSpacing.spacingMD),
                      if (widget.isEditing) ...[
                        AppSvgIcon(
                          key: const ValueKey('chat-edit-pencil'),
                          assetPath: AppIcons.edit,
                          size: 16,
                          color: borderColor,
                        ),
                        SizedBox(width: AppSpacing.spacingSM),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_name != null)
                              AppText(
                                _name!,
                                style: AppTypography.caption.copyWith(
                                  color: borderColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                              ),
                            if (_name != null && _message != null)
                              const SizedBox(height: 2),
                            if (_message != null)
                              AppText(
                                _preview(_message!, _type),
                                style: AppTypography.caption.copyWith(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                      if (widget.onCancel != null)
                        IconButton(
                          key: const ValueKey('chat-reply-cancel'),
                          onPressed: _visible ? widget.onCancel : null,
                          tooltip: widget.isEditing
                              ? 'Cancel edit'
                              : 'Cancel reply',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            tapTargetSize: MaterialTapTargetSize.padded,
                            padding: EdgeInsets.zero,
                          ),
                          icon: DecoratedBox(
                            decoration: BoxDecoration(
                              color: secondaryTextColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: AppSvgIcon(
                                assetPath: AppIcons.close,
                                size: 14,
                                color: secondaryTextColor,
                              ),
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
      ),
    );
  }

  String _preview(String message, String? type) {
    if (type == 'image') return '📷 Photo';
    if (type == 'video') return '🎥 Video';
    if (type == 'audio') return '🎤 Audio';
    if (type == 'file') return '📎 File';
    return message;
  }
}
