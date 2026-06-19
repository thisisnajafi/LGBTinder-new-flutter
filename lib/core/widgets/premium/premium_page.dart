import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';
import '../../../routes/app_router.dart';
import 'premium_shell.dart';

/// Premium header for main-tab screens (Settings, Notifications, Messenger).
class PremiumPageHeader extends StatelessWidget {
  const PremiumPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final bool showBackButton;
  final VoidCallback? onBack;

  static const double horizontalPadding = AppSpacing.spacingLG;

  static void defaultBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        showBackButton ? AppSpacing.spacingXS : horizontalPadding,
        AppSpacing.spacingSM,
        horizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBackButton)
                IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.arrowLeft,
                    size: 24,
                    color: textColor,
                  ),
                  onPressed: onBack ?? () => defaultBack(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: AppColors.brandGradient,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab-screen layout with premium header and scrollable body.
class PremiumTabPageLayout extends StatelessWidget {
  const PremiumTabPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.body,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumPageHeader(
              title: title,
              subtitle: subtitle,
              action: action,
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Pushed detail screen shell (settings sub-pages, filters, etc.).
class PremiumDetailScaffold extends StatelessWidget {
  const PremiumDetailScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.action,
    this.onBack,
    this.bottomNavigationBar,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? action;
  final VoidCallback? onBack;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumPageHeader(
              title: title,
              subtitle: subtitle,
              action: action,
              showBackButton: true,
              onBack: onBack,
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Horizontal category chips for filters / notification groups.
class PremiumCategoryChips extends StatelessWidget {
  const PremiumCategoryChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            PremiumTapScale(
              onTap: () => onSelected(i),
              semanticLabel: labels[i],
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: selectedIndex == i
                      ? AppColors.brandGradient
                      : null,
                  color: selectedIndex == i
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.06),
                  border: Border.all(
                    color: selectedIndex == i
                        ? Colors.transparent
                        : AppColors.accentViolet.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selectedIndex == i
                            ? Colors.white
                            : AppColors.accentViolet,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
