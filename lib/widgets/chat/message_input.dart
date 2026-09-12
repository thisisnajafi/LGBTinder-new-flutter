// Widget: MessageInput
// Message input field with actions
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/services/app_logger.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/chat/providers/chat_thread_providers.dart';
import '../../features/chat/utils/chat_voice_record_gesture.dart';
import 'chat_send_morph_icon.dart';
import 'chat_voice_record_bar.dart';
import '../../features/chat/utils/chat_send_celebration.dart';

/// Message input field widget
/// Text input with send button and media options
class MessageInput extends ConsumerStatefulWidget {
  final Function(String)? onSend;
  final bool celebrateSend;
  final Function(String)? onTextChanged;
  final ValueChanged<bool>? onFocusChange;
  final Function()? onMediaTap;
  final Function()? onMediaLongPress;
  /// Returns `false` when recording did not start (permission denied).
  final Future<bool> Function()? onVoiceRecordStart;
  final Future<void> Function()? onVoiceRecordSend;
  final Future<void> Function()? onVoiceRecordCancel;
  final String? hintText;
  final bool enabled;
  final bool isEditing;
  final int? peerUserId;

  const MessageInput({
    Key? key,
    this.onSend,
    this.celebrateSend = true,
    this.onTextChanged,
    this.onFocusChange,
    this.onMediaTap,
    this.onMediaLongPress,
    this.onVoiceRecordStart,
    this.onVoiceRecordSend,
    this.onVoiceRecordCancel,
    this.hintText,
    this.enabled = true,
    this.isEditing = false,
    this.peerUserId,
  }) : super(key: key);

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _isHoldingToRecord = false;
  bool _isRecordingLocked = false;
  bool _didCancelRecordingBySlide = false;
  bool _sendLocked = false;
  double _holdStartX = 0;
  double _holdStartY = 0;
  late final AnimationController _micPulseController;
  late final Animation<double> _micPulseAnimation;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _micPulseAnimation = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );
    // Rebuild send button when text changes (enabled state + gradient).
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    widget.onFocusChange?.call(_focusNode.hasFocus);
  }

  void _applyPendingDraft(PendingChatDraft? draft) {
    if (draft == null) return;
    final peerId = widget.peerUserId;
    if (peerId == null || draft.userId != peerId) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final text = draft.text.trim();
    if (text.isEmpty) return;
    if (_controller.text == text) {
      ref.read(pendingChatDraftProvider.notifier).state = null;
      return;
    }

    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onTextChanged?.call(text);
    _focusNode.requestFocus();
    ref.read(pendingChatDraftProvider.notifier).state = null;
    if (mounted) setState(() {});
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
    if (oldWidget.isEditing && !widget.isEditing && _controller.text.isNotEmpty) {
      _controller.clear();
      widget.onTextChanged?.call('');
    }
  }

  @override
  void dispose() {
    _micPulseController.dispose();
    _recordingTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_sendLocked) return;
    final text = _controller.text.trim();
    if (text.isEmpty || widget.onSend == null) return;

    // Lock for this frame so IME submit + send-button tap cannot both fire.
    _sendLocked = true;
    _controller.clear();
    widget.onTextChanged?.call('');
    if (widget.celebrateSend) {
      ChatSendCelebration.tryPlay(context: context, text: text);
    }
    widget.onSend!(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendLocked = false;
    });
  }

  void _resetRecordingUi() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _micPulseController.stop();
    _micPulseController.reset();
    if (mounted) {
      setState(() {
        _isHoldingToRecord = false;
        _isRecordingLocked = false;
        _didCancelRecordingBySlide = false;
        _recordingSeconds = 0;
      });
    }
  }

  Future<void> _startRecordingHold(LongPressStartDetails details) async {
    if (_isHoldingToRecord) return;
    if (!widget.enabled || _controller.text.trim().isNotEmpty) return;
    if (widget.onVoiceRecordStart == null) return;
    _holdStartX = details.globalPosition.dx;
    _holdStartY = details.globalPosition.dy;
    _didCancelRecordingBySlide = false;
    _isRecordingLocked = false;

    try {
      final started = await widget.onVoiceRecordStart!.call();
      if (!started) return;
    } catch (e) {
      AppLogger.warning(
        'Voice record start failed',
        tag: 'Chat',
        error: e,
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isHoldingToRecord = true;
      _recordingSeconds = 0;
    });
    if (AppAnimations.animationsEnabled(context)) {
      _micPulseController.repeat(reverse: true);
    } else {
      _micPulseController.value = 1;
    }
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

  Future<void> _onHoldEnd() async {
    if (_isRecordingLocked) return;
    await _sendRecording();
  }

  Future<void> _cancelRecording() async {
    if (!_isHoldingToRecord) return;
    AppHaptics.medium();
    _resetRecordingUi();
    await widget.onVoiceRecordCancel?.call();
  }

  void _lockRecording() {
    if (!_isHoldingToRecord || _isRecordingLocked || _didCancelRecordingBySlide) {
      return;
    }
    AppHaptics.medium();
    _micPulseController.stop();
    _micPulseController.value = 1;
    setState(() => _isRecordingLocked = true);
  }

  void _onRecordingMove(LongPressMoveUpdateDetails details) {
    if (!_isHoldingToRecord ||
        _didCancelRecordingBySlide ||
        _isRecordingLocked) {
      return;
    }
    final action = ChatVoiceRecordGesture.resolve(
      dx: details.globalPosition.dx - _holdStartX,
      dy: details.globalPosition.dy - _holdStartY,
    );
    if (action == ChatVoiceRecordAction.cancel) {
      _didCancelRecordingBySlide = true;
      unawaited(_cancelRecording());
      return;
    }
    if (action == ChatVoiceRecordAction.lock) {
      _lockRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatComposerState>(
      chatComposerProvider(widget.peerUserId ?? 0),
      (previous, next) {
        if (widget.peerUserId == null) return;
        if (next.replyMessageId == null) return;
        if (previous?.replyMessageId == next.replyMessageId) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      },
    );

    final pendingDraft = ref.watch(pendingChatDraftProvider);
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    if (isCurrentRoute && pendingDraft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyPendingDraft(ref.read(pendingChatDraftProvider));
      });
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final hasText = _controller.text.trim().isNotEmpty;
    final canRecord = !widget.isEditing &&
        !hasText &&
        widget.onVoiceRecordStart != null;
    final maxInputHeight =
        (MediaQuery.sizeOf(context).height * 0.25).clamp(80.0, 160.0);
    final actionSize =
        (MediaQuery.sizeOf(context).width * 0.11).clamp(44.0, 52.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        border: Border(
          top: BorderSide(
            color: AppColors.accentViolet.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Padding(
        padding: ResponsivePadding.horizontal(context).copyWith(
          top: AppSpacing.spacingMD,
          bottom: AppSpacing.spacingMD,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: maxInputHeight,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    border: Border.all(
                      color: AppColors.accentViolet.withValues(alpha: 0.12),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppAnimations.animationsEnabled(context)
                        ? const Duration(milliseconds: 220)
                        : Duration.zero,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _isHoldingToRecord
                        ? LayoutBuilder(
                            key: const ValueKey('recording'),
                            builder: (context, constraints) {
                              return ChatVoiceRecordBar(
                                seconds: _recordingSeconds,
                                locked: _isRecordingLocked,
                                compact: constraints.maxWidth < 300,
                                onDiscard: () =>
                                    unawaited(_cancelRecording()),
                              );
                            },
                          )
                        : TextField(
                            key: const ValueKey('text-input'),
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
                            style:
                                AppTypography.body.copyWith(color: textColor),
                            decoration: InputDecoration(
                              hintText:
                                  widget.hintText ?? 'Type a message...',
                              hintStyle: AppTypography.body.copyWith(
                                color: secondaryTextColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.spacingLG,
                                vertical: AppSpacing.spacingMD,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              AnimatedSize(
                duration: AppAnimations.chatSendMorphDuration(context),
                curve: AppAnimations.curveDefault,
                alignment: Alignment.centerRight,
                child: widget.onMediaTap != null &&
                        !_isHoldingToRecord &&
                        !hasText &&
                        !widget.isEditing
                    ? Padding(
                        key: const ValueKey('chat-attach-button'),
                        padding: const EdgeInsets.only(
                          right: AppSpacing.spacingXS,
                        ),
                        child: GestureDetector(
                          onLongPress:
                              widget.enabled ? widget.onMediaLongPress : null,
                          child: PremiumTapScale(
                            onTap:
                                widget.enabled ? widget.onMediaTap! : () {},
                            semanticLabel: 'Attach media',
                            child: Container(
                              width: actionSize,
                              height: actionSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentViolet
                                    .withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AppColors.accentViolet
                                      .withValues(alpha: 0.14),
                                ),
                              ),
                              child: Center(
                                child: AppSvgIcon(
                                  assetPath: AppIcons.attach,
                                  size: 20,
                                  color: AppColors.accentViolet,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: canRecord && !_isRecordingLocked
                    ? (d) => unawaited(_startRecordingHold(d))
                    : null,
                onLongPressMoveUpdate:
                    _isHoldingToRecord && !_isRecordingLocked
                        ? _onRecordingMove
                        : null,
                onLongPressEnd: _isHoldingToRecord
                    ? (_) => unawaited(_onHoldEnd())
                    : null,
                child: ScaleTransition(
                  scale: _isHoldingToRecord && !_isRecordingLocked
                      ? _micPulseAnimation
                      : const AlwaysStoppedAnimation(1),
                  child: AnimatedContainer(
                    key: ChatSendCelebration.sendOriginKey,
                    duration: AppAnimations.chatSendMorphDuration(context),
                    curve: AppAnimations.curveDefault,
                    decoration: BoxDecoration(
                      gradient: (hasText || _isHoldingToRecord) &&
                              widget.enabled
                          ? AppTheme.accentGradient
                          : null,
                      color: (!hasText && !_isHoldingToRecord) ||
                              !widget.enabled
                          ? secondaryTextColor.withValues(alpha: 0.3)
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: IgnorePointer(
                      ignoring: !hasText && !_isRecordingLocked,
                      child: IconButton(
                        key: _isRecordingLocked
                            ? const ValueKey('chat-voice-locked-send')
                            : const ValueKey('chat-voice-mic'),
                        tooltip: _isRecordingLocked
                            ? 'Send recording'
                            : widget.isEditing
                                ? 'Save edit'
                                : (hasText ? 'Send message' : 'Record voice'),
                        icon: ChatSendMorphIcon(
                          hasText: hasText || _isRecordingLocked,
                          isEditing: widget.isEditing,
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed: !widget.enabled
                            ? null
                            : _isRecordingLocked
                                ? () => unawaited(_sendRecording())
                                : hasText
                                    ? _handleSend
                                    : null,
                        padding: EdgeInsets.all(
                          AppSpacing.spacingSM + 2,
                        ),
                        constraints: BoxConstraints(
                          minWidth: actionSize,
                          minHeight: actionSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
