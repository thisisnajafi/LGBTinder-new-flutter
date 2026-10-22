import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../routes/app_router.dart';

/// One upgrade card for every blurred older message in the thread.
class ChatOlderMessagesCard extends StatelessWidget {
  const ChatOlderMessagesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacingLG,
        AppSpacing.spacingSM,
        AppSpacing.spacingLG,
        AppSpacing.spacingSM,
      ),
      child: Semantics(
        button: true,
        label: 'Upgrade to read older messages',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoutes.subscriptionPlans),
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
            child: Ink(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardBackgroundDark
                    : AppColors.cardBackgroundLight,
                borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                border: Border.all(
                  color: AppColors.accentViolet.withValues(alpha: 0.22),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingSM,
                ),
                child: Row(
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.lock,
                      size: 20,
                      color: AppColors.accentViolet,
                    ),
                    const SizedBox(width: AppSpacing.spacingSM),
                    Expanded(
                      child: Text(
                        'Upgrade to read older messages',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
