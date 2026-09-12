// Widget: PinnedMessagesBanner — premium pinned messages strip
import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../core/responsive/responsive.dart';

/// Banner showing pinned message count; tap jumps to the pin (CHAT-FEAT-005).
class PinnedMessagesBanner extends StatelessWidget {
  static const Key barKey = ValueKey('chat-pinned-banner');

  final int pinnedCount;
  final String? preview;
  final VoidCallback? onTap;

  const PinnedMessagesBanner({
    super.key,
    required this.pinnedCount,
    this.preview,
    this.onTap,
  });

  String get _label {
    if (pinnedCount <= 0) return '';
    final trimmed = preview?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return '$pinnedCount pinned message${pinnedCount > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final show = pinnedCount > 0;
    final duration = AppAnimations.chatPinnedBannerDuration(context);

    return ClipRect(
      child: AnimatedContainer(
        key: barKey,
        duration: duration,
        curve: AppAnimations.curveDefault,
        height: show ? AppAnimations.chatPinnedBannerHeight : 0,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: AppAnimations.chatPinnedBannerHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PremiumPageHeader.horizontalPadding,
            ),
            child: PremiumTapScale(
              onTap: show ? (onTap ?? () {}) : () {},
              semanticLabel: _label,
              child: Row(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.bookmark,
                    size: 16,
                    color: AppColors.accentViolet,
                  ),
                  const SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: AppText(
                      _label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  AppSvgIcon(
                    assetPath: AppIcons.arrowDown,
                    size: 16,
                    color: AppColors.accentViolet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
