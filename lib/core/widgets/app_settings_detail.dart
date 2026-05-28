import 'package:flutter/material.dart';

import '../theme/spacing_constants.dart';
import 'app_grouped_list_card.dart';
import 'app_page_header.dart';
import 'app_page_scaffold.dart';

/// Shared layout tokens for settings hub detail screens.
class AppSettingsLayout {
  AppSettingsLayout._();

  static const double horizontalPadding = AppPageHeader.horizontalPadding;

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

/// Standard back-nav settings detail shell (matches settings hub).
class AppSettingsDetailScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? action;
  final VoidCallback? onBack;

  const AppSettingsDetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: title,
      showBackButton: true,
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

/// Builds a grouped single-choice section (radio-style options in one card).
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
        AppGroupedListSection(
          title: title,
          padding: padding,
          children: [
            for (var i = 0; i < options.length; i++)
              AppGroupedOptionTile(
                label: options[i].value,
                isSelected: value == options[i].key,
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(options[i].key),
                showDivider: i < options.length - 1,
              ),
          ],
        ),
        if (footnote != null) AppSettingsSectionFootnote(text: footnote!),
      ],
    );
  }
}
