import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/border_radius_constants.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';
import '../profile_image_widget.dart';

/// Shared page header chrome from the other-user profile hero:
/// rounded card, soft pink wash, optional blurred cover, circular back.
class PremiumHeroHeader extends StatelessWidget {
  const PremiumHeroHeader({
    super.key,
    required this.child,
    this.onBack,
    this.coverImageUrl,
    this.inlineBack = true,
    this.transparentSides = false,
    this.overAmbientBackground = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.spacingLG,
      AppSpacing.spacingMD,
      AppSpacing.spacingLG,
      AppSpacing.spacingMD,
    ),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onBack;
  final String? coverImageUrl;
  /// When true, the back control sits in the same row as [child].
  final bool inlineBack;
  /// Translucent glass fill for page title capsules (full pill, no side fade).
  final bool transparentSides;
  /// Lets a page wallpaper show through the capsule instead of a blurred cover.
  final bool overAmbientBackground;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  static const double horizontalPadding = AppSpacing.spacingLG;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(
      transparentSides ? AppRadius.radiusRound : AppRadius.radiusXL,
    );

    return Padding(
      padding: margin ??
          const EdgeInsets.fromLTRB(
            AppSpacing.spacingLG,
            AppSpacing.spacingXS,
            AppSpacing.spacingLG,
            0,
          ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: _HeroCoverWash(
                  imageUrl: overAmbientBackground ? null : coverImageUrl,
                  isDark: isDark,
                  glass: transparentSides,
                  overAmbientBackground: overAmbientBackground,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.28),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding,
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (onBack == null) {
      return child;
    }

    if (!inlineBack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PremiumHeroBackButton(onTap: onBack!),
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          child,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PremiumHeroBackButton(onTap: onBack!),
        const SizedBox(width: AppSpacing.spacingSM),
        Expanded(child: child),
      ],
    );
  }
}

/// Circular glass back control used on the profile hero and all page headers.
class PremiumHeroBackButton extends StatelessWidget {
  const PremiumHeroBackButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: AppIcons.arrowLeft,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCoverWash extends StatelessWidget {
  const _HeroCoverWash({
    required this.imageUrl,
    required this.isDark,
    this.glass = false,
    this.overAmbientBackground = false,
  });

  final String? imageUrl;
  final bool isDark;
  /// Translucent frosted fill that covers the full capsule, including rounded ends.
  final bool glass;
  final bool overAmbientBackground;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (glass) {
      final fill = overAmbientBackground
          ? (isDark
              ? [
                  AppColors.surfaceDark.withValues(alpha: 0.42),
                  Color.lerp(
                    AppColors.surfaceDark,
                    AppColors.accentViolet,
                    0.18,
                  )!.withValues(alpha: 0.48),
                  Color.lerp(
                    AppColors.surfaceDark,
                    AppColors.accentPink,
                    0.14,
                  )!.withValues(alpha: 0.46),
                ]
              : [
                  Colors.white.withValues(alpha: 0.42),
                  Color.lerp(
                    Colors.white,
                    AppColors.accentViolet,
                    0.1,
                  )!.withValues(alpha: 0.48),
                  Color.lerp(
                    Colors.white,
                    AppColors.accentPink,
                    0.08,
                  )!.withValues(alpha: 0.46),
                ])
          : (isDark
              ? [
                  AppColors.surfaceDark.withValues(alpha: 0.78),
                  Color.lerp(
                    AppColors.surfaceDark,
                    AppColors.accentViolet,
                    0.18,
                  )!.withValues(alpha: 0.82),
                  Color.lerp(
                    AppColors.surfaceDark,
                    AppColors.accentPink,
                    0.14,
                  )!.withValues(alpha: 0.82),
                ]
              : [
                  Colors.white.withValues(alpha: 0.86),
                  Color.lerp(
                    Colors.white,
                    AppColors.accentViolet,
                    0.1,
                  )!.withValues(alpha: 0.88),
                  Color.lerp(
                    Colors.white,
                    AppColors.accentPink,
                    0.08,
                  )!.withValues(alpha: 0.88),
                ]);

      return Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Transform.scale(
                scale: 1.15,
                child: ProfileImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: const ColoredBox(color: Colors.transparent),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: fill,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Transform.scale(
              scale: 1.15,
              child: ProfileImageWidget(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentGradientStart,
                  AppColors.accentViolet,
                  AppColors.accentPink,
                ],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.backgroundDark.withValues(alpha: 0.55),
                      AppColors.backgroundDark.withValues(alpha: 0.88),
                      AppColors.backgroundDark.withValues(alpha: 0.96),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.96),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentViolet.withValues(alpha: isDark ? 0.22 : 0.12),
                AppColors.accentPink.withValues(alpha: isDark ? 0.14 : 0.08),
                AppColors.feedbackInfo.withValues(alpha: isDark ? 0.1 : 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
