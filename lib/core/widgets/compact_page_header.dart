import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';

/// Single-row tab header shared by Discover, Messenger, Notifications, and
/// the other main tabs.
///
/// The bar is 56–64dp, inset by [horizontalMargin] on both sides, and stays
/// inside the safe area. Title and actions are vertically centered. A subtitle
/// is smaller and is omitted when the width is under [narrowWidth].
class CompactPageHeader extends StatelessWidget {
  const CompactPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final String? subtitle;

  /// One trailing control (search, overflow menu, text button).
  final Widget? action;

  /// Trailing icon buttons. Gaps between them are [actionGap].
  final List<Widget> actions;

  /// Optional leading back control. Tabs leave this null.
  final VoidCallback? onBack;

  /// Distance from the screen (or parent) edge to the bar. Never zero.
  static const double horizontalMargin = AppSpacing.spacingLG;

  static const double actionGap = 8;

  /// Subtitle is dropped below this width so the title stays on one row.
  static const double narrowWidth = 360;

  static const double minHeight = 56;
  static const double maxHeight = 64;

  static const Key cardKey = Key('compact-page-header-card');
  static const Key rowKey = Key('compact-page-header-row');
  static const Key titleBlockKey = Key('compact-page-header-title');

  bool _showSubtitle(double width) {
    final text = subtitle?.trim();
    if (text == null || text.isEmpty) return false;
    return width >= narrowWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSubtitle = _showSubtitle(constraints.maxWidth);
          final height = showSubtitle ? maxHeight : minHeight;
          final trailing = <Widget>[
            ...actions,
            if (action != null) action!,
          ];

          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              horizontalMargin,
              AppSpacing.spacingXS,
              horizontalMargin,
              0,
            ),
            child: Semantics(
              header: true,
              namesRoute: true,
              label: title,
              child: ClipRRect(
                key: cardKey,
                borderRadius: BorderRadius.circular(height / 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: isDark
                          ? [
                              AppColors.surfaceDark.withValues(alpha: 0.94),
                              Color.lerp(
                                AppColors.surfaceDark,
                                AppColors.accentViolet,
                                0.22,
                              )!,
                              Color.lerp(
                                AppColors.surfaceDark,
                                AppColors.accentPink,
                                0.16,
                              )!,
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.96),
                              Color.lerp(
                                Colors.white,
                                AppColors.accentViolet,
                                0.08,
                              )!,
                              Color.lerp(
                                Colors.white,
                                AppColors.accentPink,
                                0.06,
                              )!,
                            ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.55),
                      width: 0.5,
                    ),
                  ),
                  child: SizedBox(
                    key: rowKey,
                    height: height,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.spacingMD,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (onBack != null) ...[
                            _BackButton(onBack: onBack!),
                            const SizedBox(width: actionGap),
                          ],
                          Expanded(
                            child: ClampedTextScale(
                              child: KeyedSubtree(
                                key: titleBlockKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: titleColor,
                                        height: 1.1,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (showSubtitle) ...[
                                      const SizedBox(height: 2),
                                      AppText(
                                        subtitle!.trim(),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: muted,
                                          height: 1.1,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (trailing.isNotEmpty) ...[
                            const SizedBox(width: actionGap),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                for (var i = 0; i < trailing.length; i++) ...[
                                  if (i > 0) const SizedBox(width: actionGap),
                                  trailing[i],
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return IconButton(
      tooltip: 'Back',
      onPressed: onBack,
      visualDensity: VisualDensity.compact,
      icon: Transform.flip(
        flipX: rtl,
        child: AppSvgIcon(
          assetPath: AppIcons.arrowLeft,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
