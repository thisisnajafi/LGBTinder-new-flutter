import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/utils/chat_forward_attribution.dart';

/// Compact “Forwarded from” row inside a bubble (CHAT-THREAD-008).
class ChatForwardedHeader extends StatelessWidget {
  final String? name;
  final bool isSent;

  const ChatForwardedHeader({
    super.key,
    this.name,
    this.isSent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSent
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
        : AppColors.accentPurple;

    return Semantics(
      label: ChatForwardAttribution.label(name),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.spacingXS),
        child: Row(
          children: [
            AppSvgIcon(
              assetPath: AppIcons.forward,
              size: 14,
              color: color,
            ),
            const SizedBox(width: AppSpacing.spacingXS),
            Expanded(
              child: AppText(
                ChatForwardAttribution.label(name),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
