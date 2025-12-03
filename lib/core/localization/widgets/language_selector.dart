import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../locale_provider.dart';

/// Language selector widget
/// Allows users to select their preferred language
class LanguageSelector extends ConsumerWidget {
  final bool showCurrentLanguage;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const LanguageSelector({
    Key? key,
    this.showCurrentLanguage = true,
    this.padding,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);

    return Card(
      elevation: elevation ?? 2,
      color: backgroundColor ?? (Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Language',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Choose your preferred language',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 16),

            // Current language display (if enabled)
            if (showCurrentLanguage) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryLight.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Language',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            localeState.isLoading
                                ? 'Loading...'
                                : localeState.currentLocale.languageCode == 'en'
                                    ? 'English'
                                    : _getLanguageDisplayName(localeState.currentLocale),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Language list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: SupportedLocales.all.length,
              itemBuilder: (context, index) {
                final locale = SupportedLocales.all[index];
                final isSelected = locale.languageCode == localeState.currentLocale.languageCode;

                return LanguageListTile(
                  locale: locale,
                  isSelected: isSelected,
                  onTap: () => _changeLanguage(context, ref, locale),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(BuildContext context, WidgetRef ref, Locale locale) async {
    try {
      await ref.read(localeProvider.notifier).setLocale(locale);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to ${_getLanguageDisplayName(locale)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change language: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getLanguageDisplayName(Locale locale) {
    return SupportedLocales.getDisplayName(locale);
  }
}

/// Language list tile widget
class LanguageListTile extends ConsumerWidget {
  final Locale locale;
  final bool isSelected;
  final VoidCallback? onTap;

  const LanguageListTile({
    Key? key,
    required this.locale,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRTL = SupportedLocales.isRTL(locale);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Flag or language icon placeholder
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight.withOpacity(0.2)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _getLanguageFlag(locale),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Language info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SupportedLocales.getDisplayName(locale),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryLight
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isRTL) ...[
                    const SizedBox(height: 2),
                    Text(
                      'RTL',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selection indicator
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLanguageFlag(Locale locale) {
    // Return flag emoji or language code
    switch (locale.languageCode) {
      case 'en': return '🇺🇸';
      case 'es': return '🇪🇸';
      case 'fr': return '🇫🇷';
      case 'de': return '🇩🇪';
      case 'it': return '🇮🇹';
      case 'pt': return '🇵🇹';
      case 'ru': return '🇷🇺';
      case 'zh': return '🇨🇳';
      case 'ja': return '🇯🇵';
      case 'ko': return '🇰🇷';
      case 'ar': return '🇸🇦';
      case 'hi': return '🇮🇳';
      default: return locale.languageCode.toUpperCase();
    }
  }
}

/// Compact language selector (dropdown style)
class CompactLanguageSelector extends ConsumerWidget {
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CompactLanguageSelector({
    Key? key,
    this.width,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);

    return Container(
      width: width ?? 150,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: localeState.currentLocale,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          items: SupportedLocales.all.map((locale) {
            return DropdownMenuItem(
              value: locale,
              child: Row(
                children: [
                  Text(
                    _getLanguageFlag(locale),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      SupportedLocales.getDisplayName(locale),
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (locale) async {
            if (locale != null) {
              try {
                await ref.read(localeProvider.notifier).setLocale(locale);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to change language'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  String _getLanguageFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return '🇺🇸';
      case 'es': return '🇪🇸';
      case 'fr': return '🇫🇷';
      case 'de': return '🇩🇪';
      case 'it': return '🇮🇹';
      case 'pt': return '🇵🇹';
      case 'ru': return '🇷🇺';
      case 'zh': return '🇨🇳';
      case 'ja': return '🇯🇵';
      case 'ko': return '🇰🇷';
      case 'ar': return '🇸🇦';
      case 'hi': return '🇮🇳';
      default: return '🌐';
    }
  }
}
