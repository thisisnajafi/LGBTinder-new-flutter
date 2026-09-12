import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../features/chat/providers/chat_outbox_ui_provider.dart';
import '../../features/chat/utils/chat_outbox_ui.dart';

/// Clock + “Sending queued…” strip while this peer has outbox rows.
class ChatOutboxBanner extends ConsumerWidget {
  const ChatOutboxBanner({
    super.key,
    required this.peerUserId,
    this.visibleOverride,
  });

  final int peerUserId;

  /// Tests inject visibility so they do not need a live outbox.
  final bool? visibleOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outbox = ref.watch(chatOutboxUiProvider);
    final visible = visibleOverride ?? outbox.visibleFor(peerUserId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final duration = AppAnimations.animationsEnabled(context)
        ? AppAnimations.feedbackShort
        : Duration.zero;
    final iconColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return AnimatedOpacity(
      duration: duration,
      opacity: visible ? 1 : 0,
      child: visible
          ? Semantics(
              label: ChatOutboxUi.sendingQueuedLabel,
              child: Material(
                color: bg,
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
                          assetPath: AppIcons.clock,
                          size: 18,
                          color: iconColor,
                        ),
                        const SizedBox(width: AppSpacing.spacingSM),
                        Expanded(
                          child: AppText(
                            ChatOutboxUi.sendingQueuedLabel,
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
            )
          : const SizedBox.shrink(),
    );
  }
}
