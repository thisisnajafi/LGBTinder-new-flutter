import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';
import 'app_grouped_list_card.dart';
import 'premium/premium_design_system.dart';

/// Title Case for settings page headings (every word capitalized).
String formatSettingsTitle(String title) {
  if (title.trim().isEmpty) return title;
  return title.split(RegExp(r'\s+')).map((segment) {
    if (segment == '&') return segment;
    if (segment.contains('-')) {
      return segment.split('-').map(_titleCaseWord).join('-');
    }
    return _titleCaseWord(segment);
  }).join(' ');
}

String _titleCaseWord(String word) {
  if (word.isEmpty) return word;
  if (word.length <= 4 && word == word.toUpperCase()) return word;
  return word[0].toUpperCase() + word.substring(1).toLowerCase();
}

/// Shared layout tokens for settings hub detail screens.
class AppSettingsLayout {
  AppSettingsLayout._();

  static const double horizontalPadding = PremiumPageHeader.horizontalPadding;

  static const EdgeInsets firstSectionPadding = EdgeInsets.fromLTRB(
    horizontalPadding,
    0,
    horizontalPadding,
    0,
  );

  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(
    horizontalPadding,
    AppSpacing.spacingXL,
    horizontalPadding,
    0,
  );
}

/// Premium settings detail shell — matches own-profile design language.
class AppSettingsDetailScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? action;
  final VoidCallback? onBack;
  final String? subtitle;

  const AppSettingsDetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.onBack,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumDetailScaffold(
      title: formatSettingsTitle(title),
      subtitle: subtitle,
      action: action,
      onBack: onBack,
      body: body,
    );
  }
}

/// Scrollable body for settings detail pages.
class AppSettingsDetailList extends StatelessWidget {
  final List<Widget> children;

  const AppSettingsDetailList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingXXL),
      children: children,
    );
  }
}

/// Muted helper copy below a settings section.
class AppSettingsSectionFootnote extends StatelessWidget {
  final String text;

  const AppSettingsSectionFootnote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSettingsLayout.horizontalPadding + AppSpacing.spacingXS,
        AppSpacing.spacingSM,
        AppSettingsLayout.horizontalPadding,
        0,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Padded content inside a grouped settings card (forms, custom blocks).
class AppSettingsInset extends StatelessWidget {
  final Widget child;

  const AppSettingsInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      child: child,
    );
  }
}

/// Builds a grouped single-choice section inside premium shell.
class AppSettingsOptionSection extends StatelessWidget {
  final String title;
  final String? footnote;
  final String value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry? padding;

  const AppSettingsOptionSection({
    super.key,
    required this.title,
    this.footnote,
    required this.value,
    required this.options,
    this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumSettingsGroup(
          title: title,
          children: [
            for (var i = 0; i < options.length; i++)
              PremiumSettingsTile(
                iconPath: AppIcons.getIconPath('tick-circle'),
                title: options[i].value,
                accent: value == options[i].key
                    ? AppColors.accentPink
                    : AppColors.accentViolet,
                onTap: onChanged == null ? () {} : () => onChanged!(options[i].key),
                trailing: value == options[i].key
                    ? AppSvgIcon(
                        assetPath: AppIcons.checkCircle,
                        size: 20,
                        color: AppColors.accentPink,
                      )
                    : null,
              ),
          ],
        ),
        if (footnote != null) AppSettingsSectionFootnote(text: footnote!),
      ],
    );
  }
}
