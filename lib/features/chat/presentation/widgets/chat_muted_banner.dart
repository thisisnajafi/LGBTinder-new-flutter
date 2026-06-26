import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';

/// Premium strip shown when conversation notifications are muted.
class ChatMutedBanner extends StatelessWidget {
  const ChatMutedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumPageHeader.horizontalPadding,
        AppSpacing.spacingSM,
        PremiumPageHeader.horizontalPadding,
        AppSpacing.spacingXS,
      ),
      child: PremiumShell(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.feedbackWarning.withValues(alpha: 0.14),
              ),
              child: Center(
                child: AppSvgIcon(
                  assetPath: AppIcons.bellSlash,
                  size: 16,
                  color: AppColors.feedbackWarning,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacingSM),
            Expanded(
              child: Text(
                'Notifications muted for this chat',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
