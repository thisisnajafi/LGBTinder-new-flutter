import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';

/// Onboarding page widget
/// Individual page in the onboarding flow with illustration and content
class OnboardingPage extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String? description;
  final String? illustrationPath;
  final IconData? iconData;
  final Widget? customIllustration;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final double? illustrationHeight;
  final CrossAxisAlignment contentAlignment;

  const OnboardingPage({
    Key? key,
    required this.title,
    required this.subtitle,
    this.description,
    this.illustrationPath,
    this.iconData,
    this.customIllustration,
    this.actions,
    this.padding,
    this.backgroundColor,
    this.titleColor,
    this.subtitleColor,
    this.illustrationHeight,
    this.contentAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: backgroundColor ?? (isDark ? AppColors.backgroundDark : Colors.white),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: contentAlignment,
        children: [
          // Illustration
          if (customIllustration != null) ...[
            SizedBox(
              height: illustrationHeight ?? 200,
              child: customIllustration!,
            ),
          ] else if (illustrationPath != null) ...[
            Container(
              height: illustrationHeight ?? 200,
              width: illustrationHeight ?? 200,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppSvgIcon(
                  assetPath: illustrationPath!,
                  size: 100,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ] else if (iconData != null) ...[
            Container(
              height: illustrationHeight ?? 200,
              width: illustrationHeight ?? 200,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  iconData,
                  size: 100,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ] else ...[
            // Default illustration placeholder
            Container(
              height: illustrationHeight ?? 200,
              width: illustrationHeight ?? 200,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.favorite,
                  size: 100,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Title
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor ?? theme.colorScheme.onSurface,
              height: 1.2,
            ),
            textAlign: contentAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: subtitleColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: contentAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
          ),

          // Description (if provided)
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: contentAlignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : TextAlign.start,
            ),
          ],

          // Actions (if provided)
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: contentAlignment,
              children: actions!.map((action) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: action,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Onboarding page with gradient background
class GradientOnboardingPage extends OnboardingPage {
  final List<Color> gradientColors;

  const GradientOnboardingPage({
    Key? key,
    required String title,
    required String subtitle,
    String? description,
    String? illustrationPath,
    IconData? iconData,
    Widget? customIllustration,
    List<Widget>? actions,
    EdgeInsetsGeometry? padding,
    Color? titleColor,
    Color? subtitleColor,
    double? illustrationHeight,
    CrossAxisAlignment contentAlignment = CrossAxisAlignment.center,
    this.gradientColors = const [Color(0xFF667EEA), Color(0xFF764BA2)],
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          description: description,
          illustrationPath: illustrationPath,
          iconData: iconData,
          customIllustration: customIllustration,
          actions: actions,
          padding: padding,
          titleColor: titleColor ?? Colors.white,
          subtitleColor: subtitleColor ?? Colors.white70,
          illustrationHeight: illustrationHeight,
          contentAlignment: contentAlignment,
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: super.build(context, ref),
    );
  }
}

/// LGBT+ themed onboarding page
class LGBTOnboardingPage extends OnboardingPage {
  const LGBTOnboardingPage({
    Key? key,
    required String title,
    required String subtitle,
    String? description,
    String? illustrationPath,
    IconData? iconData,
    Widget? customIllustration,
    List<Widget>? actions,
    EdgeInsetsGeometry? padding,
    Color? titleColor,
    Color? subtitleColor,
    double? illustrationHeight,
    CrossAxisAlignment contentAlignment = CrossAxisAlignment.center,
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          description: description,
          illustrationPath: illustrationPath,
          iconData: iconData,
          customIllustration: customIllustration,
          actions: actions,
          padding: padding,
          backgroundColor: AppColors.primaryLight.withOpacity(0.05),
          titleColor: titleColor ?? AppColors.primaryLight,
          subtitleColor: subtitleColor,
          illustrationHeight: illustrationHeight,
          contentAlignment: contentAlignment,
        );
}

/// Pride flag background onboarding page
class PrideOnboardingPage extends OnboardingPage {
  const PrideOnboardingPage({
    Key? key,
    required String title,
    required String subtitle,
    String? description,
    String? illustrationPath,
    IconData? iconData,
    Widget? customIllustration,
    List<Widget>? actions,
    EdgeInsetsGeometry? padding,
    Color? titleColor,
    Color? subtitleColor,
    double? illustrationHeight,
    CrossAxisAlignment contentAlignment = CrossAxisAlignment.center,
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          description: description,
          illustrationPath: illustrationPath,
          iconData: iconData,
          customIllustration: customIllustration,
          actions: actions,
          padding: padding,
          backgroundColor: Colors.white,
          titleColor: titleColor ?? AppColors.primaryLight,
          subtitleColor: subtitleColor,
          illustrationHeight: illustrationHeight,
          contentAlignment: contentAlignment,
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.lgbtGradient,
        ),
      ),
      child: Stack(
        children: [
          // Pride flag stripes
          Positioned.fill(
            child: Column(
              children: AppColors.lgbtGradient.map((color) {
                return Expanded(
                  child: Container(color: color.withOpacity(0.1)),
                );
              }).toList(),
            ),
          ),
          // Content
          super.build(context, ref),
        ],
      ),
    );
  }
}
