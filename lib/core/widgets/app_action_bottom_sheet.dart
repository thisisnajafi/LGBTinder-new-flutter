import 'package:flutter/material.dart';

import '../theme/border_radius_constants.dart';
import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart' show AppIcons, AppSvgIcon;

/// Shared visual tokens — capsule and icon boxes use the same corner radius.
abstract final class AppBottomSheetStyle {
  static const double cornerRadius = AppRadius.radiusLG;
  static const double iconBoxSize = 36;
  static const double handleWidth = 36;
  static const double handleHeight = 4;
}

/// One tappable row inside an action bottom sheet.
class AppActionSheetItem {
  final String iconPath;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const AppActionSheetItem({
    required this.iconPath,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });
}

/// Floating, settings-style bottom sheet shell used across the app.
class AppActionBottomSheet {
  AppActionBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    List<AppActionSheetItem> actions = const [],
    Widget? body,
    bool showCancel = true,
    bool isScrollControlled = true,
  }) {
    assert(actions.isNotEmpty || body != null,
        'Provide actions or a custom body.');
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (ctx) => AppBottomSheetShell(
        title: title,
        actions: actions,
        body: body,
        showCancel: showCancel,
      ),
    );
  }
}

/// Reusable shell: drag handle, floating card(s), optional cancel pill.
class AppBottomSheetShell extends StatelessWidget {
  final String? title;
  final List<AppActionSheetItem> actions;
  final Widget? body;
  final bool showCancel;
  final EdgeInsetsGeometry? padding;

  const AppBottomSheetShell({
    super.key,
    this.title,
    this.actions = const [],
    this.body,
    this.showCancel = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomSafe = mediaQuery.padding.bottom;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    // Keep the sheet above the keyboard without growing past the viewport.
    final maxHeight = (screenHeight - keyboardInset) * 0.92;

    return AnimatedPadding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            AppSpacing.spacingMD,
            0,
            AppSpacing.spacingMD,
            bottomSafe + AppSpacing.spacingMD,
          ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(color: theme.colorScheme.onSurface.withValues(alpha: 0.22)),
              if (body != null)
                Flexible(child: body!)
              else
                AppBottomSheetCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null) _TitleHeader(title: title!),
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const AppBottomSheetDivider(),
                        AppBottomSheetActionTile(item: actions[i]),
                      ],
                    ],
                  ),
                ),
              if (showCancel) ...[
                const SizedBox(height: AppSpacing.spacingSM),
                AppBottomSheetCard(
                  child: AppBottomSheetActionTile(
                    item: AppActionSheetItem(
                      iconPath: AppIcons.close,
                      label: 'Cancel',
                      iconColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomSheetCard extends StatelessWidget {
  final Widget child;

  const AppBottomSheetCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppBottomSheetStyle.cornerRadius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _DragHandle extends StatelessWidget {
  final Color color;

  const _DragHandle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppBottomSheetStyle.handleWidth,
      height: AppBottomSheetStyle.handleHeight,
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _TitleHeader extends StatelessWidget {
  final String title;

  const _TitleHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacingMD,
        AppSpacing.spacingMD,
        AppSpacing.spacingMD,
        AppSpacing.spacingXS,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class AppBottomSheetDivider extends StatelessWidget {
  const AppBottomSheetDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: AppSpacing.spacingMD +
          AppBottomSheetStyle.iconBoxSize +
          AppSpacing.spacingMD,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.35),
    );
  }
}

class AppBottomSheetActionTile extends StatelessWidget {
  final AppActionSheetItem item;

  const AppBottomSheetActionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = item.iconColor ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingMD,
            ),
            child: Row(
              children: [
                Container(
                  width: AppBottomSheetStyle.iconBoxSize,
                  height: AppBottomSheetStyle.iconBoxSize,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      AppBottomSheetStyle.cornerRadius,
                    ),
                  ),
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: item.iconPath,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable list body for picker sheets (single / multi select).
class AppBottomSheetListBody extends StatelessWidget {
  final String title;
  final Widget? header;
  final Widget child;
  final double maxHeightFactor;

  const AppBottomSheetListBody({
    super.key,
    required this.title,
    required this.child,
    this.header,
    this.maxHeightFactor = 0.72,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;

    return AppBottomSheetCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight * maxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TitleHeader(title: title),
            if (header != null) header!,
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Primary / secondary buttons inside a bottom sheet card.
class AppBottomSheetConfirmBody extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const AppBottomSheetConfirmBody({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBottomSheetCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
