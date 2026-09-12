import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../responsive/responsive.dart';
import '../../theme/app_colors.dart';
import '../../theme/spacing_constants.dart';
import '../../../routes/app_router.dart';
import 'premium_hero_header.dart';
import 'premium_layout.dart';
import 'premium_refresh.dart';
import 'premium_shell.dart';

/// Premium header for main-tab and detail screens.
/// Uses [PremiumHeroHeader] (same card as the profile hero).
class PremiumPageHeader extends StatelessWidget {
  const PremiumPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.showBackButton = false,
    this.onBack,
    this.coverImageUrl,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String? coverImageUrl;

  static const double horizontalPadding = PremiumHeroHeader.horizontalPadding;

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

    return PremiumHeroHeader(
      onBack: showBackButton
          ? (onBack ?? () => defaultBack(context))
          : null,
      coverImageUrl: coverImageUrl,
      transparentSides: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: (showBackButton
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineMedium)
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                  maxLines: 2,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  AppText(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
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
    this.showTitleHeader = true,
    this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget body;
  final bool showTitleHeader;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final header = showTitleHeader
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumPageHeader(
                title: title,
                subtitle: subtitle,
                action: action,
              ),
              const SizedBox(height: AppSpacing.spacingSM),
            ],
          )
        : null;

    final Widget content;
    if (onRefresh != null && header != null) {
      content = PremiumRefreshScope(
        onRefresh: onRefresh!,
        header: header,
        body: body,
      );
    } else if (onRefresh != null) {
      content = PremiumRefreshIndicator(
        onRefresh: onRefresh!,
        notificationPredicate: PremiumRefreshIndicator.nested,
        child: body,
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header,
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: PremiumSafeArea(
        child: ResponsiveGrid.constrained(context, content),
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
    this.floatingActionButton,
    this.showBackButton = true,
    this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? action;
  final VoidCallback? onBack;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumPageHeader(
          title: title,
          subtitle: subtitle,
          action: action,
          showBackButton: showBackButton,
          onBack: onBack,
        ),
        const SizedBox(height: AppSpacing.spacingSM),
      ],
    );

    final content = onRefresh != null
        ? PremiumRefreshScope(
            onRefresh: onRefresh!,
            header: header,
            body: body,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(child: body),
            ],
          );

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: PremiumSafeArea(
        bottom: true,
        child: ResponsiveGrid.constrained(context, content),
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
    this.subtleSelection = false,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool subtleSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
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
                  gradient: selectedIndex == i && !subtleSelection
                      ? AppColors.brandGradient
                      : null,
                  color: selectedIndex == i
                      ? (subtleSelection
                          ? primary.withValues(alpha: 0.15)
                          : null)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  border: Border.all(
                    color: selectedIndex == i
                        ? (subtleSelection ? primary : Colors.transparent)
                        : AppColors.accentViolet.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selectedIndex == i
                        ? (subtleSelection ? primary : Colors.white)
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
