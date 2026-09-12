import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive_text.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_action_bottom_sheet.dart';
import '../../features/chat/utils/chat_message_sheet_actions.dart';

/// Floating long-press menu scaled from the bubble
/// (CHAT-ANIM-006 / CHAT-THREAD-007).
class ChatMessageContextMenu {
  ChatMessageContextMenu._();

  static const double menuWidth = 280;

  static double estimatedHeight({
    required int actionCount,
    required bool showReact,
    int subtitleCount = 0,
  }) {
    const tile = 48.0;
    const subtitleExtra = 8.0;
    const react = 52.0;
    return (showReact ? react : 0) +
        actionCount * tile +
        subtitleCount * subtitleExtra;
  }

  static Future<void> show({
    required BuildContext context,
    required Offset anchor,
    required bool isSent,
    required List<AppActionSheetItem> actions,
    ValueChanged<String>? onReact,
    bool showReact = false,
  }) {
    AppHaptics.medium();
    final animate = AppAnimations.animationsEnabled(context);
    return Navigator.of(context).push(
      _ChatMessageContextMenuRoute(
        anchor: anchor,
        isSent: isSent,
        actions: actions,
        onReact: onReact,
        showReact: showReact,
        animate: animate,
      ),
    );
  }

  static Offset clampOrigin({
    required Size screen,
    required Offset anchor,
    required bool isSent,
    required double menuHeight,
    required EdgeInsets padding,
  }) {
    final maxLeft = screen.width - padding.right - menuWidth;
    final minLeft = padding.left;
    final left = isSent
        ? (anchor.dx - menuWidth).clamp(minLeft, maxLeft)
        : anchor.dx.clamp(minLeft, maxLeft);
    final maxTop = screen.height - padding.bottom - menuHeight;
    final top = (anchor.dy - menuHeight - AppSpacing.spacingSM)
        .clamp(padding.top, maxTop);
    return Offset(left.toDouble(), top.toDouble());
  }
}

class _ChatMessageContextMenuRoute extends PopupRoute<void> {
  _ChatMessageContextMenuRoute({
    required this.anchor,
    required this.isSent,
    required this.actions,
    required this.onReact,
    required this.showReact,
    required this.animate,
  });

  final Offset anchor;
  final bool isSent;
  final List<AppActionSheetItem> actions;
  final ValueChanged<String>? onReact;
  final bool showReact;
  final bool animate;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Dismiss message menu';

  @override
  Color get barrierColor => Colors.transparent;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration =>
      animate ? AppAnimations.chatContextMenu : Duration.zero;

  @override
  Duration get reverseTransitionDuration =>
      animate ? AppAnimations.chatContextMenu : Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ChatMessageContextMenuPage(
      animation: animation,
      anchor: anchor,
      isSent: isSent,
      actions: actions,
      onReact: onReact,
      showReact: showReact,
      animate: animate,
    );
  }
}

class _ChatMessageContextMenuPage extends StatelessWidget {
  final Animation<double> animation;
  final Offset anchor;
  final bool isSent;
  final List<AppActionSheetItem> actions;
  final ValueChanged<String>? onReact;
  final bool showReact;
  final bool animate;

  const _ChatMessageContextMenuPage({
    required this.animation,
    required this.anchor,
    required this.isSent,
    required this.actions,
    required this.onReact,
    required this.showReact,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final menuHeight = ChatMessageContextMenu.estimatedHeight(
      actionCount: actions.length,
      showReact: showReact,
      subtitleCount: actions
          .where(
            (item) => item.subtitle != null && item.subtitle!.trim().isNotEmpty,
          )
          .length,
    );
    final origin = ChatMessageContextMenu.clampOrigin(
      screen: media.size,
      anchor: anchor,
      isSent: isSent,
      menuHeight: menuHeight,
      padding: media.padding + const EdgeInsets.all(AppSpacing.spacingMD),
    );

    final scale = animate
        ? animation.drive(
            Tween<double>(begin: 0, end: 1).chain(
              CurveTween(curve: AppAnimations.chatContextMenuCurve),
            ),
          )
        : const AlwaysStoppedAnimation<double>(1);

    Widget scrim = ColoredBox(
      color: theme.colorScheme.scrim.withValues(alpha: 0.18),
    );
    if (animate) {
      scrim = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppAnimations.chatContextMenuBlur,
          sigmaY: AppAnimations.chatContextMenuBlur,
        ),
        child: scrim,
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: scrim,
            ),
          ),
          Positioned(
            left: origin.dx,
            top: origin.dy,
            width: ChatMessageContextMenu.menuWidth,
            child: ScaleTransition(
              alignment:
                  isSent ? Alignment.bottomRight : Alignment.bottomLeft,
              scale: scale,
              child: _MenuCard(
                actions: actions,
                showReact: showReact,
                onReact: onReact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<AppActionSheetItem> actions;
  final bool showReact;
  final ValueChanged<String>? onReact;

  const _MenuCard({
    required this.actions,
    required this.showReact,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReact) _ReactRow(onReact: onReact),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0 || showReact)
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            _ActionTile(item: actions[i]),
          ],
        ],
      ),
    );
  }
}

class _ReactRow extends StatelessWidget {
  final ValueChanged<String>? onReact;

  const _ReactRow({required this.onReact});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingXS,
        vertical: AppSpacing.spacingXS,
      ),
      child: Row(
        children: [
          for (final emoji in ChatMessageSheetActions.reactEmojis)
            Expanded(
              child: Semantics(
                button: true,
                label: 'React $emoji',
                child: InkWell(
                  onTap: onReact == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          onReact!(emoji);
                        },
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Text(emoji, style: style),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final AppActionSheetItem item;

  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = item.iconColor ?? theme.colorScheme.primary;
    final isDestructive = item.iconColor != null &&
        item.iconColor != theme.colorScheme.primary;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        item.onTap();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: item.subtitle != null && item.subtitle!.trim().isNotEmpty
              ? 56
              : 48,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingMD),
          child: Row(
            children: [
              AppSvgIcon(
                assetPath: item.iconPath,
                size: 24,
                color: iconColor,
              ),
              const SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      item.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? iconColor
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                    ),
                    if (item.subtitle != null && item.subtitle!.trim().isNotEmpty)
                      AppText(
                        item.subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
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
