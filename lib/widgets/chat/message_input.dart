// Widget: MessageInput
// Message input field with actions
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';

/// Message input field widget
/// Text input with send button and media options
class MessageInput extends ConsumerStatefulWidget {
  final Function(String)? onSend;
  final Function(String)? onTextChanged;
  final Function()? onMediaTap;
  final Function()? onMediaLongPress;
  final Future<void> Function()? onVoiceRecordStart;
  final Future<void> Function()? onVoiceRecordSend;
  final Future<void> Function()? onVoiceRecordCancel;
  final String? hintText;
  final bool enabled;

  const MessageInput({
    Key? key,
    this.onSend,
    this.onTextChanged,
    this.onMediaTap,
    this.onMediaLongPress,
    this.onVoiceRecordStart,
    this.onVoiceRecordSend,
    this.onVoiceRecordCancel,
    this.hintText,
    this.enabled = true,
  }) : super(key: key);

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _isHoldingToRecord = false;
  bool _didCancelRecordingBySlide = false;
  double _holdStartX = 0;
  static const double _cancelSlideThreshold = 72;

  @override
  void initState() {
    super.initState();
    // Rebuild send button when text changes (enabled state + gradient).
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isHoldingToRecord && _controller.text.trim().isNotEmpty) {
      _resetRecordingUi();
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
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

  void _resetRecordingUi() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (mounted) {
      setState(() {
        _isHoldingToRecord = false;
        _didCancelRecordingBySlide = false;
        _recordingSeconds = 0;
      });
    }
  }

  Future<void> _startRecordingHold(LongPressStartDetails details) async {
    if (!widget.enabled || _controller.text.trim().isNotEmpty) return;
    if (widget.onVoiceRecordStart == null) return;
    _holdStartX = details.globalPosition.dx;
    _didCancelRecordingBySlide = false;

    try {
      await widget.onVoiceRecordStart!.call();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _isHoldingToRecord = true;
      _recordingSeconds = 0;
    });
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isHoldingToRecord) return;
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _sendRecording() async {
    if (!_isHoldingToRecord || _didCancelRecordingBySlide) {
      _resetRecordingUi();
      return;
    }
    _resetRecordingUi();
    await widget.onVoiceRecordSend?.call();
  }

  Future<void> _cancelRecording() async {
    if (!_isHoldingToRecord) return;
    _resetRecordingUi();
    await widget.onVoiceRecordCancel?.call();
  }

  void _onRecordingMove(LongPressMoveUpdateDetails details) {
    if (!_isHoldingToRecord || _didCancelRecordingBySlide) return;
    final deltaX = details.globalPosition.dx - _holdStartX;
    if (deltaX <= -_cancelSlideThreshold) {
      _didCancelRecordingBySlide = true;
      unawaited(_cancelRecording());
    }
  }

  String _formatRecordingDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
    final hasText = _controller.text.trim().isNotEmpty;
    final canRecord = !hasText && widget.onVoiceRecordStart != null;

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
                child: _isHoldingToRecord
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingLG,
                          vertical: AppSpacing.spacingMD,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.feedbackError,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: AppSpacing.spacingSM),
                            Text(
                              _formatRecordingDuration(_recordingSeconds),
                              style: AppTypography.body.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: AppSpacing.spacingLG),
                            Expanded(
                              child: Text(
                                '< Slide to cancel',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : TextField(
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
            if (widget.onMediaTap != null && !_isHoldingToRecord)
              GestureDetector(
                onLongPress: widget.enabled ? widget.onMediaLongPress : null,
                child: IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.attach,
                    size: 22,
                    color: secondaryTextColor,
                  ),
                  onPressed: widget.enabled ? widget.onMediaTap : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            SizedBox(width: AppSpacing.spacingXS),
            GestureDetector(
              onLongPressStart: canRecord ? (d) => unawaited(_startRecordingHold(d)) : null,
              onLongPressMoveUpdate: canRecord ? _onRecordingMove : null,
              onLongPressEnd: canRecord ? (_) => unawaited(_sendRecording()) : null,
              child: Container(
                decoration: BoxDecoration(
                  gradient: (hasText || _isHoldingToRecord) && widget.enabled
                      ? AppTheme.accentGradient
                      : null,
                  color: (!hasText && !_isHoldingToRecord) || !widget.enabled
                      ? secondaryTextColor.withValues(alpha: 0.3)
                      : null,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: AppSvgIcon(
                    assetPath: hasText ? AppIcons.send : AppIcons.microphone,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: hasText && widget.enabled ? _handleSend : null,
                  padding: EdgeInsets.all(AppSpacing.spacingMD),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
