import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization_constants.dart';

/// Locale provider for managing app language
final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier();
});

/// Supported locales in the app
class SupportedLocales {
  static const english = Locale('en', 'US');
  static const spanish = Locale('es', 'ES');
  static const french = Locale('fr', 'FR');
  static const german = Locale('de', 'DE');
  static const italian = Locale('it', 'IT');
  static const portuguese = Locale('pt', 'PT');
  static const russian = Locale('ru', 'RU');
  static const chinese = Locale('zh', 'CN');
  static const japanese = Locale('ja', 'JP');
  static const korean = Locale('ko', 'KR');
  static const arabic = Locale('ar', 'SA');
  static const hindi = Locale('hi', 'IN');

  static List<Locale> get all => [
    english, spanish, french, german, italian, portuguese,
    russian, chinese, japanese, korean, arabic, hindi,
  ];

  static List<String> get languageCodes => all.map((locale) => locale.languageCode).toList();

  static String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'it': return 'Italiano';
      case 'pt': return 'Português';
      case 'ru': return 'Русский';
      case 'zh': return '中文';
      case 'ja': return '日本語';
      case 'ko': return '한국어';
      case 'ar': return 'العربية';
      case 'hi': return 'हिंदी';
      default: return locale.languageCode.toUpperCase();
    }
  }

  static String getNativeName(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'it': return 'Italiano';
      case 'pt': return 'Português';
      case 'ru': return 'Русский';
      case 'zh': return '中文';
      case 'ja': return '日本語';
      case 'ko': return '한국어';
      case 'ar': return 'العربية';
      case 'hi': return 'हिंदी';
      default: return locale.languageCode.toUpperCase();
    }
  }

  static bool isRTL(Locale locale) {
    return LocalizationConstants.rtlLanguages.contains(locale.languageCode);
  }
}

/// Locale state
class LocaleState {
  final Locale currentLocale;
  final List<Locale> supportedLocales;
  final bool isLoading;

  LocaleState({
    required this.currentLocale,
    this.supportedLocales = const [],
    this.isLoading = false,
  });

  LocaleState copyWith({
    Locale? currentLocale,
    List<Locale>? supportedLocales,
    bool? isLoading,
  }) {
    return LocaleState(
      currentLocale: currentLocale ?? this.currentLocale,
      supportedLocales: supportedLocales ?? this.supportedLocales,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Locale notifier
class LocaleNotifier extends StateNotifier<LocaleState> {
  static const String _localeKey = 'app_locale';

  LocaleNotifier()
      : super(LocaleState(
          currentLocale: SupportedLocales.english,
          supportedLocales: SupportedLocales.all,
        )) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocaleCode = prefs.getString(_localeKey);

      if (savedLocaleCode != null) {
        final savedLocale = _getLocaleFromCode(savedLocaleCode);
        if (savedLocale != null) {
          state = state.copyWith(
            currentLocale: savedLocale,
            isLoading: false,
          );
          return;
        }
      }

      // Default to system locale or English
      final systemLocale = _getSystemLocale();
      state = state.copyWith(
        currentLocale: systemLocale ?? SupportedLocales.english,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        currentLocale: SupportedLocales.english,
        isLoading: false,
      );
    }
  }

  Locale? _getLocaleFromCode(String code) {
    try {
      // Handle different locale code formats
      if (code.contains('_')) {
        final parts = code.split('_');
        return Locale(parts[0], parts[1]);
      } else if (code.contains('-')) {
        final parts = code.split('-');
        return Locale(parts[0], parts[1]);
      } else {
        return Locale(code);
      }
    } catch (e) {
      return null;
    }
  }

  Locale? _getSystemLocale() {
    try {
      // Get system locale (this would need to be implemented based on platform)
      // For now, return English as default
      return SupportedLocales.english;
    } catch (e) {
      return null;
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!SupportedLocales.all.contains(locale)) {
      throw Exception('Unsupported locale: ${locale.languageCode}');
    }

    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.toString());

      state = state.copyWith(
        currentLocale: locale,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> setLocaleByCode(String languageCode) async {
    final locale = SupportedLocales.all.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => SupportedLocales.english,
    );

    await setLocale(locale);
  }

  Future<void> resetToDefault() async {
    await setLocale(SupportedLocales.english);
  }

  /// Get display name for current locale
  String getCurrentLocaleDisplayName() {
    return SupportedLocales.getDisplayName(state.currentLocale);
  }

  /// Get native name for current locale
  String getCurrentLocaleNativeName() {
    return SupportedLocales.getNativeName(state.currentLocale);
  }

  /// Check if current locale is RTL
  bool get isCurrentLocaleRTL {
    return SupportedLocales.isRTL(state.currentLocale);
  }

  /// Get text direction for current locale
  TextDirection get textDirection {
    return isCurrentLocaleRTL ? TextDirection.rtl : TextDirection.ltr;
  }
}

/// Localization delegate provider
final localizationDelegateProvider = Provider<LocalizationsDelegate>((ref) {
  throw UnimplementedError('Localization delegate must be provided in the provider scope');
});
