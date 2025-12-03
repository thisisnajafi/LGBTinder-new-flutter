import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'localization_constants.dart';

/// Localization service for managing app translations
class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Map<String, Map<String, String>> _localizedStrings = {};
  String _currentLanguageCode = 'en';

  /// Initialize localization service
  Future<void> initialize() async {
    await _loadLanguage('en'); // Always load English as fallback
  }

  /// Load language translations
  Future<void> loadLanguage(String languageCode) async {
    _currentLanguageCode = languageCode;
    await _loadLanguage(languageCode);
  }

  Future<void> _loadLanguage(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/lang/${languageCode}.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings[languageCode] = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      // If language file doesn't exist, fall back to English
      if (languageCode != 'en') {
        await loadLanguage('en');
      }
    }
  }

  /// Get localized string
  String translate(String key, {Map<String, String>? params}) {
    // Try current language first
    var translation = _localizedStrings[_currentLanguageCode]?[key];

    // Fall back to English if not found
    if (translation == null && _currentLanguageCode != 'en') {
      translation = _localizedStrings['en']?[key];
    }

    // Return key if no translation found
    translation ??= key;

    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translation = translation?.replaceAll('{$paramKey}', paramValue);
      });
    }

    return translation;
  }

  /// Get pluralized string
  String plural(String key, int count, {Map<String, String>? params}) {
    final pluralKey = _getPluralKey(key, count);
    return translate(pluralKey, params: params);
  }

  String _getPluralKey(String key, int count) {
    final rule = LocalizationConstants.pluralRules[_currentLanguageCode] ?? 'english';

    switch (rule) {
      case 'english':
        return count == 1 ? key : '${key}_plural';

      case 'spanish':
      case 'french':
      case 'italian':
      case 'portuguese':
        return count == 1 ? key : '${key}_plural';

      case 'russian':
        if (count % 10 == 1 && count % 100 != 11) {
          return key;
        } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
          return '${key}_few';
        } else {
          return '${key}_many';
        }

      case 'chinese':
      case 'japanese':
      case 'korean':
        return key; // No plural forms

      case 'arabic':
        if (count == 1) {
          return key;
        } else if (count == 2) {
          return '${key}_two';
        } else if (count >= 3 && count <= 10) {
          return '${key}_few';
        } else {
          return '${key}_many';
        }

      case 'hindi':
        if (count == 1) {
          return key;
        } else {
          return '${key}_plural';
        }

      default:
        return count == 1 ? key : '${key}_plural';
    }
  }

  /// Check if a translation exists
  bool hasTranslation(String key) {
    return _localizedStrings[_currentLanguageCode]?.containsKey(key) == true ||
           (_currentLanguageCode != 'en' && _localizedStrings['en']?.containsKey(key) == true);
  }

  /// Get current language code
  String get currentLanguageCode => _currentLanguageCode;

  /// Get available languages
  List<String> get availableLanguages => LocalizationConstants.supportedLanguages.keys.toList();

  /// Get language display name
  String getLanguageDisplayName(String languageCode) {
    return LocalizationConstants.supportedLanguages[languageCode] ?? languageCode;
  }

  /// Format number according to locale
  String formatNumber(dynamic number, {String? locale}) {
    final languageCode = locale ?? _currentLanguageCode;

    // For now, return string representation
    // In a real app, you might want to use intl package
    return number.toString();
  }

  /// Format currency according to locale
  String formatCurrency(double amount, {String? currencyCode, String? locale}) {
    final languageCode = locale ?? _currentLanguageCode;
    final symbol = LocalizationConstants.currencySymbols[languageCode] ?? '\$';

    // For now, simple formatting
    // In a real app, you might want to use intl package
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format date according to locale
  String formatDate(DateTime date, {String? format, String? locale}) {
    final languageCode = locale ?? _currentLanguageCode;
    final dateFormat = LocalizationConstants.dateFormats[languageCode] ?? 'MM/dd/yyyy';

    // For now, simple formatting
    // In a real app, you might want to use intl package
    return '${date.month.toString().padLeft(2, '0')}/'
           '${date.day.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  /// Format time according to locale
  String formatTime(DateTime time, {String? format, String? locale}) {
    final languageCode = locale ?? _currentLanguageCode;
    final timeFormat = LocalizationConstants.timeFormats[languageCode] ?? 'h:mm a';

    // For now, simple formatting
    // In a real app, you might want to use intl package
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Get text direction for current language
  TextDirection get textDirection {
    return LocalizationConstants.rtlLanguages.contains(_currentLanguageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Check if current language is RTL
  bool get isRTL => LocalizationConstants.rtlLanguages.contains(_currentLanguageCode);
}

/// Extension on BuildContext to easily access localization
extension LocalizationExtension on BuildContext {
  LocalizationService get loc => LocalizationService();

  String tr(String key, {Map<String, String>? params}) {
    return LocalizationService().translate(key, params: params);
  }

  String plural(String key, int count, {Map<String, String>? params}) {
    return LocalizationService().plural(key, count, params: params);
  }
}

/// Extension on String for easy translation
extension StringLocalization on String {
  String tr(BuildContext context, {Map<String, String>? params}) {
    return LocalizationService().translate(this, params: params);
  }

  String plural(BuildContext context, int count, {Map<String, String>? params}) {
    return LocalizationService().plural(this, count, params: params);
  }
}
