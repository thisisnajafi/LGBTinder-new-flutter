import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// API for locale/language endpoints (routes 22, 23, 40, 41).
class LocaleApiService {
  final ApiService _apiService;

  LocaleApiService(this._apiService);

  /// GET locales — list available languages (no auth).
  /// Response: data.languages = [{ code, name, native_name, flag, direction }].
  Future<List<LocaleLanguage>> getLocales() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.locales,
        fromJson: (json) => json as Map<String, dynamic>,
        useCache: true,
      );
      if (!response.isSuccess || response.data == null) return [];
      final data = response.data!;
      final list = data['languages'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => LocaleLanguage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// GET locales/translations — get translation map for a locale (no auth).
  /// Optional query: locale (e.g. "en"). Response: data.locale, data.translations.
  Future<LocaleTranslations?> getTranslations({String? locale}) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.localesTranslations,
        queryParameters: locale != null ? {'locale': locale} : null,
        fromJson: (json) => json as Map<String, dynamic>,
        useCache: true,
      );
      if (!response.isSuccess || response.data == null) return null;
      return LocaleTranslations.fromJson(response.data!);
    } catch (_) {
      return null;
    }
  }

  /// GET locales/current — current user locale (auth required).
  Future<CurrentLocale?> getCurrentLocale() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.localesCurrent,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return null;
      return CurrentLocale.fromJson(response.data!);
    } catch (_) {
      return null;
    }
  }

  /// PUT locales — set user locale (auth required). Body: { "locale": "en" }.
  Future<CurrentLocale?> setLocale(String localeCode) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.locales,
        data: {'locale': localeCode},
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return null;
      return CurrentLocale.fromJson(response.data!);
    } catch (_) {
      return null;
    }
  }
}

class LocaleLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String? flag;
  final String? direction;

  LocaleLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    this.flag,
    this.direction,
  });

  factory LocaleLanguage.fromJson(Map<String, dynamic> json) {
    return LocaleLanguage(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nativeName: json['native_name']?.toString() ?? json['name']?.toString() ?? '',
      flag: json['flag']?.toString(),
      direction: json['direction']?.toString(),
    );
  }
}

class LocaleTranslations {
  final String locale;
  final Map<String, String> translations;

  LocaleTranslations({required this.locale, required this.translations});

  factory LocaleTranslations.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final locale = data['locale']?.toString() ?? 'en';
    final raw = data['translations'] as Map<String, dynamic>? ?? {};
    final translations = raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    return LocaleTranslations(locale: locale, translations: translations);
  }
}

class CurrentLocale {
  final String locale;
  final LocaleLanguage? language;

  CurrentLocale({required this.locale, this.language});

  factory CurrentLocale.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final lang = data['language'] as Map<String, dynamic>?;
    return CurrentLocale(
      locale: data['locale']?.toString() ?? 'en',
      language: lang != null ? LocaleLanguage.fromJson(lang) : null,
    );
  }
}
