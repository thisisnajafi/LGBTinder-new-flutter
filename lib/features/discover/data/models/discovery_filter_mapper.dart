import 'package:flutter/material.dart';

/// Maps discovery filter UI state ↔ API query parameters for nearby-suggestions.
class DiscoveryFilterMapper {
  DiscoveryFilterMapper._();

  static const premiumOnlyKeys = <String>{
    'verified_only',
    'online_only',
    'premium_only',
    'smoke',
    'drink',
    'gym',
    'interest_ids',
    'job_ids',
    'education_ids',
    'language_ids',
    'music_genre_ids',
    'relation_goal_ids',
    'preferred_gender_ids',
    'country',
    'city',
  };

  /// Build GET query params from stored filter map (API format).
  static Map<String, dynamic> toQueryParameters(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return {};

    final params = <String, dynamic>{};

    void addRaw(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;
      params[key] = value;
    }

    void addBoolFlag(String key, dynamic value) {
      if (value == true || value == 1 || value == '1') {
        params[key] = '1';
      }
    }

    addRaw('min_age', filters['min_age']);
    addRaw('max_age', filters['max_age']);
    addRaw('max_distance', filters['max_distance']);

    final genderIds = filters['gender_ids'] ?? filters['genders'];
    if (genderIds != null) {
      addRaw('gender_ids', _joinIds(genderIds));
    }

    addBoolFlag('verified_only', filters['verified_only']);
    addBoolFlag('online_only', filters['online_only']);
    addBoolFlag('premium_only', filters['premium_only']);

    for (final key in [
      'interest_ids',
      'job_ids',
      'education_ids',
      'language_ids',
      'music_genre_ids',
      'relation_goal_ids',
      'preferred_gender_ids',
    ]) {
      if (filters[key] != null) {
        addRaw(key, _joinIds(filters[key]));
      }
    }

    if (filters.containsKey('smoke')) {
      addRaw('smoke', _boolParam(filters['smoke']));
    }
    if (filters.containsKey('drink')) {
      addRaw('drink', _boolParam(filters['drink']));
    }
    if (filters.containsKey('gym')) {
      addRaw('gym', _boolParam(filters['gym']));
    }

    addRaw('country', filters['country']);
    addRaw('city', filters['city']);

    return params;
  }

  /// Convert filter screen result to API map (applies premium stripping for free users).
  static Map<String, dynamic> fromUiResult(
    Map<String, dynamic> ui, {
    required bool isPremium,
  }) {
    final api = <String, dynamic>{};

    if (ui['ageRange'] is RangeValues) {
      final ageRange = ui['ageRange'] as RangeValues;
      api['min_age'] = ageRange.start.round();
      api['max_age'] = ageRange.end.round();
    }

    if (ui['maxDistance'] != null) {
      api['max_distance'] = (ui['maxDistance'] as num).round();
    }

    final genderIds = ui['genderIds'];
    if (genderIds is List<int> && genderIds.isNotEmpty) {
      api['gender_ids'] = genderIds.join(',');
    }

    if (isPremium) {
      if (ui['verifiedOnly'] == true) api['verified_only'] = true;
      if (ui['onlineOnly'] == true) api['online_only'] = true;
      if (ui['premiumOnly'] == true) api['premium_only'] = true;

      _copyIdList(api, 'interest_ids', ui['interestIds']);
      _copyIdList(api, 'job_ids', ui['jobIds']);
      _copyIdList(api, 'education_ids', ui['educationIds']);
      _copyIdList(api, 'language_ids', ui['languageIds']);
      _copyIdList(api, 'music_genre_ids', ui['musicGenreIds']);
      _copyIdList(api, 'relation_goal_ids', ui['relationGoalIds']);

      if (ui.containsKey('matchSmoke')) {
        api['smoke'] = ui['matchSmoke'] == true;
      }
      if (ui.containsKey('matchDrink')) {
        api['drink'] = ui['matchDrink'] == true;
      }
      if (ui.containsKey('matchGym')) {
        api['gym'] = ui['matchGym'] == true;
      }

      final country = ui['country']?.toString().trim();
      if (country != null && country.isNotEmpty) {
        api['country'] = country;
      }
      final city = ui['city']?.toString().trim();
      if (city != null && city.isNotEmpty) {
        api['city'] = city;
      }
    }

    return api;
  }

  /// Seed filter screen UI defaults from stored API map.
  static Map<String, dynamic> toUiSeed(Map<String, dynamic>? api) {
    if (api == null || api.isEmpty) {
      return {
        'ageRange': const RangeValues(18, 35),
        'maxDistance': 50.0,
        'genderIds': <int>[],
        'verifiedOnly': false,
        'onlineOnly': false,
        'premiumOnly': false,
        'interestIds': <int>[],
        'jobIds': <int>[],
        'educationIds': <int>[],
        'languageIds': <int>[],
        'musicGenreIds': <int>[],
        'relationGoalIds': <int>[],
        'matchSmoke': null,
        'matchDrink': null,
        'matchGym': null,
        'country': '',
        'city': '',
      };
    }

    final minAge = _parseInt(api['min_age']) ?? 18;
    final maxAge = _parseInt(api['max_age']) ?? 35;

    return {
      'ageRange': RangeValues(minAge.toDouble(), maxAge.toDouble()),
      'maxDistance': (_parseInt(api['max_distance']) ?? 50).toDouble(),
      'genderIds': _parseIdList(api['gender_ids'] ?? api['genders']),
      'verifiedOnly': _parseBool(api['verified_only']),
      'onlineOnly': _parseBool(api['online_only']),
      'premiumOnly': _parseBool(api['premium_only']),
      'interestIds': _parseIdList(api['interest_ids']),
      'jobIds': _parseIdList(api['job_ids']),
      'educationIds': _parseIdList(api['education_ids']),
      'languageIds': _parseIdList(api['language_ids']),
      'musicGenreIds': _parseIdList(api['music_genre_ids']),
      'relationGoalIds': _parseIdList(api['relation_goal_ids']),
      'matchSmoke': api.containsKey('smoke') ? _parseBool(api['smoke']) : null,
      'matchDrink': api.containsKey('drink') ? _parseBool(api['drink']) : null,
      'matchGym': api.containsKey('gym') ? _parseBool(api['gym']) : null,
      'country': api['country']?.toString() ?? '',
      'city': api['city']?.toString() ?? '',
    };
  }

  static Map<String, dynamic> stripPremiumKeys(Map<String, dynamic> api) {
    return Map<String, dynamic>.from(api)
      ..removeWhere((key, _) => premiumOnlyKeys.contains(key));
  }

  static void _copyIdList(
    Map<String, dynamic> target,
    String key,
    dynamic value,
  ) {
    if (value is! List<int> || value.isEmpty) return;
    target[key] = value.join(',');
  }

  static String? _joinIds(dynamic value) {
    if (value is List) {
      if (value.isEmpty) return null;
      return value.map((e) => e.toString()).join(',');
    }
    if (value is String && value.isNotEmpty) return value;
    if (value is int) return value.toString();
    return null;
  }

  static String _boolParam(dynamic value) => _parseBool(value) ? '1' : '0';

  static bool _parseBool(dynamic value) {
    if (value == true || value == 1 || value == '1') return true;
    return false;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<int> _parseIdList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e is int ? e : int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return value
          .split(',')
          .map((part) => int.tryParse(part.trim()))
          .whereType<int>()
          .toList();
    }
    if (value is int) return [value];
    return [];
  }
}
