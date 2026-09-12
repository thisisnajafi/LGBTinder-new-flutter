/// Chip copy for the Discover active-filters bar (HOME-FILTER-001).
class DiscoverActiveFilterLabels {
  DiscoverActiveFilterLabels._();

  static List<String> fromMap(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return const [];

    final labels = <String>[];
    final maxDistance = filters['max_distance'];
    if (maxDistance != null) {
      labels.add('${maxDistance}km');
    }

    final minAge = filters['min_age'];
    final maxAge = filters['max_age'];
    if (minAge != null || maxAge != null) {
      labels.add('${minAge ?? 18}–${maxAge ?? 99}');
    }

    if (_isTrue(filters['online_only'])) labels.add('Online');
    if (_isTrue(filters['verified_only'])) labels.add('Verified');
    if (_isTrue(filters['premium_only'])) labels.add('Premium');

    _addCounted(labels, filters['gender_ids'] ?? filters['genders'], 'gender', 'genders');
    _addCounted(labels, filters['interest_ids'], 'interest', 'interests');
    _addCounted(labels, filters['relation_goal_ids'], 'goal', 'goals');
    _addCounted(labels, filters['job_ids'], 'profession', 'professions');
    _addCounted(labels, filters['education_ids'], 'education', 'educations');
    _addCounted(labels, filters['language_ids'], 'language', 'languages');
    _addCounted(labels, filters['music_genre_ids'], 'genre', 'genres');

    if (_hasValue(filters['smoke']) ||
        _hasValue(filters['drink']) ||
        _hasValue(filters['gym']) ||
        _hasValue(filters['match_smoke']) ||
        _hasValue(filters['match_drink']) ||
        _hasValue(filters['match_gym'])) {
      labels.add('Lifestyle');
    }

    final city = filters['city']?.toString().trim();
    final country = filters['country']?.toString().trim();
    if (city != null && city.isNotEmpty) {
      labels.add(city);
    } else if (country != null && country.isNotEmpty) {
      labels.add(country);
    }

    if (labels.isEmpty) {
      labels.add('Custom filters');
    }
    return labels;
  }

  static void _addCounted(
    List<String> labels,
    dynamic value,
    String singular,
    String plural,
  ) {
    final count = _idCount(value);
    if (count <= 0) return;
    labels.add(count == 1 ? '1 $singular' : '$count $plural');
  }

  static int _idCount(dynamic value) {
    if (value is List) {
      return value.where((e) => e != null && e.toString().trim().isNotEmpty).length;
    }
    if (value is String) {
      return value
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .length;
    }
    if (value is int) return 1;
    return 0;
  }

  static bool _isTrue(dynamic value) =>
      value == true || value == 1 || value == '1';

  static bool _hasValue(dynamic value) => value != null;
}
