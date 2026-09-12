import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/discover/providers/discovery_filters_provider.dart';

void main() {
  test('filters survive a new Discovery page read and clear wipes them', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(discoveryFiltersProvider.notifier).setFilters({
      'max_distance': 40,
      'online_only': true,
    });
    expect(container.read(discoveryFiltersProvider)?['max_distance'], 40);

    // Same provider instance is what DiscoveryPage watches after leaving the tab.
    expect(container.read(discoveryFiltersProvider)?['online_only'], true);

    container.read(discoveryFiltersProvider.notifier).clear();
    expect(container.read(discoveryFiltersProvider), isNull);
  });
}
