import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/responsive/responsive.dart';

/// In-place replacement for Flutter's default red error screen.
///
/// Opaque so a failed off-stage tab cannot ghost over the current route.
/// Does not show raw Dart exceptions in release builds.
class AppFrameworkErrorView extends StatelessWidget {
  const AppFrameworkErrorView({
    super.key,
    required this.details,
    this.onRetry,
  });

  final FlutterErrorDetails details;
  final VoidCallback? onRetry;

  static String userMessage(Object exception) {
    final raw = exception.toString();
    if (raw.contains('No space left') ||
        raw.contains('Writing to the log file failed') ||
        raw.contains('errno=28')) {
      return 'The server is temporarily unavailable. Try again in a moment.';
    }
    if (raw.contains('NoSuchMethodError') ||
        raw.contains('Null check operator') ||
        raw.contains('type \'Null\'')) {
      return 'This screen hit an unexpected error. Retry, or go back and open it again.';
    }
    return 'Something went wrong while drawing this screen. Retry to continue.';
  }

  @override
  Widget build(BuildContext context) {
    final platformBrightness =
        MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.dark;
    final isDark = platformBrightness == Brightness.dark;
    final hasTheme =
        context.findAncestorWidgetOfExactType<Theme>() != null;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final content = ColoredBox(
      color: background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                assetPath: AppIcons.warning2,
                size: 48,
                color: AppColors.feedbackError,
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              AppText(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.spacingSM),
              AppText(
                userMessage(details.exception),
                style: TextStyle(
                  fontSize: 14,
                  color: muted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
              ),
              if (kDebugMode &&
                  !details.exceptionAsString().contains('No space left') &&
                  !details.exceptionAsString().contains('Writing to the log')) ...[
                const SizedBox(height: AppSpacing.spacingMD),
                AppText(
                  details.exceptionAsString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: muted.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: AppSpacing.spacingXL),
              _ErrorActions(onRetry: onRetry),
            ],
          ),
        ),
      ),
    );

    if (!hasTheme) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData.dark(),
          child: Material(color: background, child: content),
        ),
      );
    }
    return Material(color: background, child: content);
  }
}

class _ErrorActions extends StatelessWidget {
  const _ErrorActions({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.maybeOf(context);
    final canPop = navigator?.canPop() ?? false;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.spacingSM,
      runSpacing: AppSpacing.spacingSM,
      children: [
        if (onRetry != null || canPop)
          FilledButton(
            onPressed: onRetry ?? () => navigator?.maybePop(),
            child: AppText(
              onRetry != null ? 'Try again' : 'Go back',
              maxLines: 1,
            ),
          ),
      ],
    );
  }
}
