import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';
import 'premium/premium_shell.dart';

/// Single-row header shared by Discover and every other page title.
///
/// The bar is always [minHeight], inset by [horizontalMargin] on both sides,
/// and stays inside the safe area. Title and round icon buttons are vertically
/// centered. [subtitle] is spoken to screen readers and does not add a second
/// line, so every screen matches the Discover header height.
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

  /// Spoken with the title. Not painted, so the bar stays one row.
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

  /// Kept so older call sites compile. The bar no longer grows on wide screens.
  static const double narrowWidth = 360;

  static const double minHeight = 56;
  static const double maxHeight = minHeight;

  static const Key cardKey = Key('compact-page-header-card');
  static const Key rowKey = Key('compact-page-header-row');
  static const Key titleBlockKey = Key('compact-page-header-title');
  static const Key backKey = Key('compact-page-header-back');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final spokenSubtitle = subtitle?.trim();
    final semanticsLabel = (spokenSubtitle == null || spokenSubtitle.isEmpty)
        ? title
        : '$title. $spokenSubtitle';

    final trailing = <Widget>[
      ...actions,
      if (action != null) action!,
    ];

    return SafeArea(
      bottom: false,
      child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              horizontalMargin,
              AppSpacing.spacingXS,
              horizontalMargin,
              0,
            ),
            child: Semantics(
              header: true,
              namesRoute: true,
              label: semanticsLabel,
              child: ClipRRect(
                key: cardKey,
                borderRadius: BorderRadius.circular(minHeight / 2),
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
                    height: minHeight,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.spacingMD,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (onBack != null) ...[
                            CompactHeaderIconButton(
                              key: backKey,
                              iconPath: AppIcons.arrowLeft,
                              semanticLabel: 'Back',
                              tooltip: 'Back',
                              mirrorInRtl: true,
                              onPressed: onBack!,
                            ),
                            const SizedBox(width: actionGap),
                          ],
                          Expanded(
                            child: ClampedTextScale(
                              child: KeyedSubtree(
                                key: titleBlockKey,
                                child: AppText(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                    height: 1.1,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
          ),
    );
  }
}

/// Round icon control used in [CompactPageHeader] (Discover passport, bell,
/// filter, back, refresh, and the same actions on every other screen).
class CompactHeaderIconButton extends StatelessWidget {
  const CompactHeaderIconButton({
    super.key,
    required this.iconPath,
    required this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.showBadge = false,
    this.mirrorInRtl = false,
  });

  final String iconPath;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final bool showBadge;

  /// Flips a directional glyph (back arrow) when the layout is RTL.
  final bool mirrorInRtl;

  static const double touchSize = 44;
  static const double faceSize = 40;
  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final face = CompactHeaderIconFace(
      iconPath: iconPath,
      showBadge: showBadge,
      mirrorInRtl: mirrorInRtl,
    );
    if (onPressed == null) {
      return Opacity(opacity: 0.4, child: face);
    }

    final button = PremiumTapScale(
      onTap: onPressed!,
      semanticLabel: semanticLabel ?? tooltip,
      child: face,
    );
    final tip = tooltip;
    if (tip == null || tip.isEmpty) return button;
    return Tooltip(message: tip, child: button);
  }
}

/// The 40dp violet circle, without its own tap handler.
///
/// Use this as the child of a menu button that already handles the press.
class CompactHeaderIconFace extends StatelessWidget {
  const CompactHeaderIconFace({
    super.key,
    required this.iconPath,
    this.showBadge = false,
    this.mirrorInRtl = false,
  });

  final String iconPath;
  final bool showBadge;
  final bool mirrorInRtl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      width: CompactHeaderIconButton.touchSize,
      height: CompactHeaderIconButton.touchSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: CompactHeaderIconButton.faceSize,
            height: CompactHeaderIconButton.faceSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentViolet.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.accentViolet.withValues(alpha: 0.16),
              ),
            ),
            child: Center(
              child: Transform.flip(
                flipX: mirrorInRtl && rtl,
                child: AppSvgIcon(
                  assetPath: iconPath,
                  size: CompactHeaderIconButton.iconSize,
                  color: AppColors.accentViolet,
                ),
              ),
            ),
          ),
          if (showBadge)
            PositionedDirectional(
              top: 4,
              end: 4,
              child: RepaintBoundary(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.accentRose,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
