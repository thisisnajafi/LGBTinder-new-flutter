import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

/// Settings section widget
/// Groups related settings together with a header
class SettingsSection extends ConsumerWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool showTopPadding;
  final bool showBottomPadding;

  const SettingsSection({
    Key? key,
    required this.title,
    required this.children,
    this.margin,
    this.padding,
    this.showTopPadding = true,
    this.showBottomPadding = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          if (showTopPadding) const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Section content
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Column(
                children: children,
              ),
            ),
          ),

          if (showBottomPadding) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Compact settings section (without background)
class CompactSettingsSection extends ConsumerWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final bool showTopPadding;
  final bool showBottomPadding;

  const CompactSettingsSection({
    Key? key,
    required this.title,
    required this.children,
    this.margin,
    this.showTopPadding = true,
    this.showBottomPadding = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          if (showTopPadding) const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Section content (no background)
          ...children,

          if (showBottomPadding) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Settings section with icon
class IconSettingsSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const IconSettingsSection({
    Key? key,
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Section content
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Column(
                children: children,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Danger settings section (for destructive actions)
class DangerSettingsSection extends ConsumerWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const DangerSettingsSection({
    Key? key,
    required this.title,
    required this.children,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.feedbackError,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Section content with danger styling
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.feedbackError.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.feedbackError.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: children,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
