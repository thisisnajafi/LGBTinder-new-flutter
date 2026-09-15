import 'package:flutter/material.dart';

import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/app_list_view.dart';
import '../../core/widgets/premium/premium_layout.dart';
import '../../features/chat/utils/chat_thread_scroll.dart';
import '../chat/message_bubble.dart';
import 'skeleton_loader.dart';

/// Skeleton loader for the live chat thread ([MessageBubble] geometry).
class SkeletonChat extends StatelessWidget {
  const SkeletonChat({super.key});

  static const int _itemCount = 6;

  @override
  Widget build(BuildContext context) {
    final line =
        (AppTypography.body.fontSize ?? 14) *
        (AppTypography.body.height ?? 1.4);
    final meta =
        AppSpacing.spacingXS +
        (AppTypography.labelSmall.fontSize ?? 11) *
            (AppTypography.labelSmall.height ?? 1.3);
    final pad = AppSpacing.spacingMD * 2;
    final oneLine = pad + line + meta;
    final twoLine = pad + line * 2 + AppSpacing.spacingXS + meta;
    final threeLine = pad + line * 3 + AppSpacing.spacingSM + meta;

    return AppListView.builder(
      reverse: ChatThreadScroll.reversed,
      physics: AppScroll.forChat(context),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
      itemCount: _itemCount,
      itemBuilder: (context, index) {
        final isSent = index.isEven;
        final maxWidth = ResponsiveGrid.chatBubbleMaxWidth(context);
        final widthFactor = 0.42 + (index % 3) * 0.14;
        final height = switch (index % 3) {
          0 => oneLine,
          1 => twoLine,
          _ => threeLine,
        };
        return Align(
          alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: MessageBubbleChrome.margin(isSent: isSent),
            child: SkeletonLoader(
              width: maxWidth * widthFactor,
              height: height,
              borderRadius: MessageBubbleChrome.radius(isSent: isSent),
            ),
          ),
        );
      },
    );
  }
}
