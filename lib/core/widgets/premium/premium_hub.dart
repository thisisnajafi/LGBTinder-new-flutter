import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/border_radius_constants.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';
import 'premium_shell.dart';

/// Hub action card data (settings, profile account hub, UI sync).
class PremiumHubActionData {
  final String iconPath;
  final String title;
  final String subtitle;
  final String? statusLabel;
  final Color? statusColor;
  final bool locked;
  final VoidCallback onTap;

  const PremiumHubActionData({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.statusLabel,
    this.statusColor,
    this.locked = false,
    required this.onTap,
  });
}

/// Back-compat alias.
typedef ProfileHubActionData = PremiumHubActionData;

/// 2-column hub grid inside a [PremiumShell].
class PremiumHubGridSection extends StatelessWidget {
  const PremiumHubGridSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final List<PremiumHubActionData> actions;

  @override
  Widget build(BuildContext context) {
    return PremiumShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.spacingMD),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: actions
                    .map((a) => SizedBox(width: w, child: PremiumHubCard(data: a)))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PremiumHubCard extends StatelessWidget {
  const PremiumHubCard({super.key, required this.data});

  final PremiumHubActionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PremiumTapScale(
      onTap: data.onTap,
      semanticLabel: data.title,
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSvgIcon(
                  assetPath: data.iconPath,
                  size: 22,
                  color: data.locked
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                      : AppColors.accentViolet,
                ),
                const Spacer(),
                if (data.locked)
                  AppSvgIcon(
                    assetPath: AppIcons.lockOutline,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  )
                else if (data.statusLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (data.statusColor ?? AppColors.feedbackSuccess)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      data.statusLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: data.statusColor ?? AppColors.feedbackSuccess,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
