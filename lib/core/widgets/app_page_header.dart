import 'package:flutter/material.dart';

import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';

/// Flat page header — replaces elevated AppBar on target screens.
class AppPageHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AppPageHeader({
    required this.title,
    this.action,
    this.showBackButton = false,
    this.onBack,
    super.key,
  });

  static const double horizontalPadding = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (showBackButton) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacingXS,
          AppSpacing.spacingSM,
          horizontalPadding,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: AppSvgIcon(
                assetPath: AppIcons.arrowLeft,
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.spacingSM,
        horizontalPadding,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
