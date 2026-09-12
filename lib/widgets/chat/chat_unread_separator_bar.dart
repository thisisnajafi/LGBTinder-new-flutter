import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../features/chat/utils/chat_unread_separator.dart';

/// Muted “— N new messages —” row with dividers (CHAT-UX-003).
class ChatUnreadSeparatorBar extends StatelessWidget {
  final int count;

  const ChatUnreadSeparatorBar({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final label = ChatUnreadSeparator.bannerLabel(count);

    return Semantics(
      header: true,
      label: ChatUnreadSeparator.labelForCount(count),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingLG,
          vertical: AppSpacing.spacingSM,
        ),
        child: Row(
          children: [
            Expanded(
              child: Divider(color: muted.withValues(alpha: 0.45)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingSM,
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ),
            Expanded(
              child: Divider(color: muted.withValues(alpha: 0.45)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrolls a reverse thread until the unread bar is in view.
class ChatUnreadSeparatorScroll {
  ChatUnreadSeparatorScroll._();

  /// Places the bar near the leading edge so unread rows fill the viewport.
  static const double alignment = 0.12;

  static Future<bool> reveal({
    required GlobalKey separatorKey,
    required ScrollController controller,
    required Duration duration,
    Curve curve = AppAnimations.curveDefault,
  }) async {
    for (var attempt = 0; attempt < 16; attempt++) {
      if (!controller.hasClients) {
        await WidgetsBinding.instance.endOfFrame;
        continue;
      }
      final ctx = separatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: alignment,
          duration: duration,
          curve: curve,
        );
        return true;
      }
      final pos = controller.position;
      if (!pos.hasContentDimensions) {
        await WidgetsBinding.instance.endOfFrame;
        continue;
      }
      if (pos.maxScrollExtent <= pos.pixels + 1) return false;
      controller.jumpTo(
        (pos.pixels + pos.viewportDimension).clamp(0.0, pos.maxScrollExtent),
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    return false;
  }
}
