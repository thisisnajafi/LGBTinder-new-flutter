import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/feature_flags_provider.dart';

/// Discovery filters (API-shaped map). Persisted in SharedPreferences so the
/// user's last selection (including genders) survives app restarts.
///
/// `null` means "no custom filters": the backend then applies the user's
/// stored matching preferences (preferred genders, age range, distance).
final discoveryFiltersProvider =
    StateNotifierProvider<DiscoveryFiltersNotifier, Map<String, dynamic>?>(
  (ref) => DiscoveryFiltersNotifier(ref.watch(sharedPreferencesProvider)),
);

class DiscoveryFiltersNotifier extends StateNotifier<Map<String, dynamic>?> {
  DiscoveryFiltersNotifier([this._prefs]) : super(_load(_prefs));

  static const storageKey = 'discovery_filters_v1';

  final SharedPreferences? _prefs;

  static Map<String, dynamic>? _load(SharedPreferences? prefs) {
    final raw = prefs?.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded.isNotEmpty) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Corrupt value: ignore and fall back to backend defaults.
    }
    return null;
  }

  void _persist() {
    final prefs = _prefs;
    if (prefs == null) return;
    final value = state;
    if (value == null || value.isEmpty) {
      prefs.remove(storageKey);
      return;
    }
    try {
      prefs.setString(storageKey, jsonEncode(value));
    } catch (_) {
      // Non-JSON value (should not happen for API-shaped maps): skip.
    }
  }

  void setFilters(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) {
      state = null;
    } else {
      state = Map<String, dynamic>.from(filters);
    }
    _persist();
  }

  void clear() {
    state = null;
    _persist();
  }
}

/// True when two filter maps encode the same query (PERF-PAGE-DISCOVERY-005).
bool discoveryFiltersEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    if (entry.value != b[entry.key] &&
        '${entry.value}' != '${b[entry.key]}') {
      return false;
    }
  }
  return true;
}
