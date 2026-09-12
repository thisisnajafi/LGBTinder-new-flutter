import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../features/chat/providers/chat_connection_ui_provider.dart';
import '../../features/chat/providers/chat_pusher_providers.dart';
import '../../features/chat/utils/chat_connection_ui.dart';

/// Telegram-style Connecting… / Tap to reconnect strip (CHAT-RT-007).
class ChatConnectionBanner extends ConsumerStatefulWidget {
  const ChatConnectionBanner({
    super.key,
    this.kindOverride,
    this.showDelay = ChatConnectionUi.showDelay,
    this.onReconnect,
  });

  /// Tests inject a kind so they do not need a live Pusher socket.
  final ChatConnectionBannerKind? kindOverride;

  /// Anti-flicker delay before first show. Hidden is always immediate.
  final Duration showDelay;

  final VoidCallback? onReconnect;

  @override
  ConsumerState<ChatConnectionBanner> createState() =>
      _ChatConnectionBannerState();
}

class _ChatConnectionBannerState extends ConsumerState<ChatConnectionBanner> {
  ChatConnectionBannerKind _shown = ChatConnectionBannerKind.hidden;
  Timer? _showTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onKind(_resolvedKind());
    });
  }

  @override
  void didUpdateWidget(ChatConnectionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kindOverride != oldWidget.kindOverride ||
        widget.showDelay != oldWidget.showDelay) {
      _onKind(_resolvedKind());
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    super.dispose();
  }

  ChatConnectionBannerKind _resolvedKind() {
    return widget.kindOverride ?? ref.read(chatConnectionBannerProvider);
  }

  void _onKind(ChatConnectionBannerKind kind) {
    _showTimer?.cancel();
    if (kind == ChatConnectionBannerKind.hidden) {
      if (_shown != kind && mounted) {
        setState(() => _shown = kind);
      }
      return;
    }
    if (_shown != ChatConnectionBannerKind.hidden) {
      if (_shown != kind && mounted) {
        setState(() => _shown = kind);
      }
      return;
    }
    void show() {
      if (!mounted) return;
      setState(() => _shown = kind);
    }

    if (widget.showDelay == Duration.zero) {
      show();
    } else {
      _showTimer = Timer(widget.showDelay, show);
    }
  }

  void _handleTap() {
    if (_shown != ChatConnectionBannerKind.tapToReconnect) return;
    final onReconnect = widget.onReconnect;
    if (onReconnect != null) {
      onReconnect();
      return;
    }
    unawaited(
      ref.read(chatPusherLifecycleProvider.notifier).reconnect(manual: true),
    );
  }

  String _iconPath(ChatConnectionBannerKind kind) {
    switch (kind) {
      case ChatConnectionBannerKind.waitingForNetwork:
        return AppIcons.wifiOff;
      case ChatConnectionBannerKind.connecting:
        return AppIcons.wifiOutline;
      case ChatConnectionBannerKind.tapToReconnect:
        return AppIcons.refreshOutline;
      case ChatConnectionBannerKind.sendingQueued:
        return AppIcons.clock;
      case ChatConnectionBannerKind.hidden:
        return AppIcons.wifiOutline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kindOverride == null) {
      ref.listen<ChatConnectionBannerKind>(
        chatConnectionBannerProvider,
        (_, next) => _onKind(next),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final duration = AppAnimations.animationsEnabled(context)
        ? AppAnimations.feedbackShort
        : Duration.zero;
    final visible = _shown != ChatConnectionBannerKind.hidden;
    final label = ChatConnectionUi.label(_shown);
    final tappable = _shown == ChatConnectionBannerKind.tapToReconnect;
    final iconColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return AnimatedOpacity(
      duration: duration,
      opacity: visible ? 1 : 0,
      child: visible
          ? Semantics(
              label: label,
              button: tappable,
              child: Material(
                color: bg,
                child: InkWell(
                  onTap: tappable ? _handleTap : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PremiumPageHeader.horizontalPadding,
                        vertical: AppSpacing.spacingSM,
                      ),
                      child: Row(
                        children: [
                          AppSvgIcon(
                            assetPath: _iconPath(_shown),
                            size: 18,
                            color: iconColor,
                          ),
                          const SizedBox(width: AppSpacing.spacingSM),
                          Expanded(
                            child: AppText(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
