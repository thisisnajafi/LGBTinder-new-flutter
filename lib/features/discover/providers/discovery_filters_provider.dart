import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped discovery filters. Survives leaving the Discover tab.
final discoveryFiltersProvider =
    StateNotifierProvider<DiscoveryFiltersNotifier, Map<String, dynamic>?>(
  (ref) => DiscoveryFiltersNotifier(),
);

class DiscoveryFiltersNotifier extends StateNotifier<Map<String, dynamic>?> {
  DiscoveryFiltersNotifier() : super(null);

  void setFilters(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) {
      state = null;
      return;
    }
    state = Map<String, dynamic>.from(filters);
  }

  void clear() => state = null;
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
