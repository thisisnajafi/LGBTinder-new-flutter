import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';

/// Spinner shown at the oldest end while history pagination runs.
class ChatLoadOlderSpinner extends StatelessWidget {
  const ChatLoadOlderSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
      child: Center(
        child: SizedBox(
          width: AppSpacing.spacingXL,
          height: AppSpacing.spacingXL,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Visible retry when the first page of older history fails.
class ChatLoadOlderRetry extends StatelessWidget {
  final VoidCallback onRetry;

  const ChatLoadOlderRetry({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
      child: Center(
        child: Semantics(
          button: true,
          label: 'Retry loading older messages',
          child: TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.refreshOutline,
                  size: 18,
                  color: color,
                ),
                SizedBox(width: AppSpacing.spacingXS),
                AppText(
                  "Couldn't load older messages · Retry",
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
