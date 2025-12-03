// Widget: MessageInput
// Message input field with actions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Message input field widget
/// Text input with send button and media options
class MessageInput extends ConsumerStatefulWidget {
  final Function(String)? onSend;
  final Function(String)? onTextChanged;
  final Function()? onMediaTap;
  final Function()? onEmojiTap;
  final String? hintText;
  final bool enabled;

  const MessageInput({
    Key? key,
    this.onSend,
    this.onTextChanged,
    this.onMediaTap,
    this.onEmojiTap,
    this.hintText,
    this.enabled = true,
  }) : super(key: key);

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.onSend != null) {
      widget.onSend!(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingMD,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.onEmojiTap != null)
              IconButton(
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  color: secondaryTextColor,
                ),
                onPressed: widget.enabled ? widget.onEmojiTap : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  onChanged: (text) {
                    if (widget.onTextChanged != null) {
                      widget.onTextChanged!(text);
                    }
                  },
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Type a message...',
                    hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingLG,
                      vertical: AppSpacing.spacingMD,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.spacingSM),
            if (widget.onMediaTap != null)
              IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: secondaryTextColor,
                ),
                onPressed: widget.enabled ? widget.onMediaTap : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            SizedBox(width: AppSpacing.spacingXS),
            Container(
              decoration: BoxDecoration(
                gradient: _controller.text.trim().isNotEmpty && widget.enabled
                    ? AppTheme.accentGradient
                    : null,
                color: _controller.text.trim().isEmpty || !widget.enabled
                    ? secondaryTextColor.withOpacity(0.3)
                    : null,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: widget.enabled && _controller.text.trim().isNotEmpty
                    ? _handleSend
                    : null,
                padding: EdgeInsets.all(AppSpacing.spacingMD),
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
