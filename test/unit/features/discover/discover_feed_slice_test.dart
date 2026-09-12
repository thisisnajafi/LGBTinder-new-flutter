import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/discover/data/models/cached_discover_item.dart';
import 'package:lgbtindernew/features/discover/data/models/discovery_profile.dart';
import 'package:lgbtindernew/features/discover/providers/discover_cache_provider.dart';
import 'package:lgbtindernew/features/discover/providers/discovery_filters_provider.dart';
import 'package:lgbtindernew/features/discover/utils/discovery_image_prefetch.dart';

DiscoveryProfile _profile(int id, {String? image}) {
  return DiscoveryProfile(
    id: id,
    firstName: 'User$id',
    primaryImageUrl: image,
  );
}

void main() {
  test('DiscoverFeedSlice ignores last-swipe and matches on stack ids', () {
    final a = DiscoverCacheState(
      items: [
        CachedDiscoverItem(profile: _profile(1)),
        CachedDiscoverItem(profile: _profile(2)),
      ],
      initialLoadComplete: true,
    );
    final b = a.copyWith(lastSwipedUserId: 9);

    expect(DiscoverFeedSlice.fromState(a), DiscoverFeedSlice.fromState(b));
    expect(DiscoverFeedSlice.fromState(a).currentUserId, 1);
    expect(DiscoverFeedSlice.fromState(a).nextUserId, 2);

    final swiped = a.copyWith(
      items: [
        CachedDiscoverItem(
          profile: _profile(1),
          interactionState: DiscoverInteractionState.liked,
        ),
        CachedDiscoverItem(profile: _profile(2)),
      ],
    );
    expect(
      DiscoverFeedSlice.fromState(a) == DiscoverFeedSlice.fromState(swiped),
      isFalse,
    );
    expect(DiscoverFeedSlice.fromState(swiped).currentUserId, 2);
  });

  test('nextCardPreviewUrls takes the first photo of the next two cards', () {
    final stack = [
      _profile(1, image: 'https://cdn.example/1.jpg'),
      _profile(2, image: 'https://cdn.example/2.jpg'),
      _profile(3, image: 'https://cdn.example/3.jpg'),
      _profile(4, image: 'https://cdn.example/4.jpg'),
    ];
    expect(
      DiscoveryImagePrefetch.nextCardPreviewUrls(stack),
      ['https://cdn.example/2.jpg', 'https://cdn.example/3.jpg'],
    );
  });

  test('discoveryFiltersEqual skips identical query maps', () {
    expect(
      discoveryFiltersEqual(
        {'max_distance': 50, 'online_only': true},
        {'max_distance': 50, 'online_only': true},
      ),
      isTrue,
    );
    expect(
      discoveryFiltersEqual(
        {'max_distance': 50},
        {'max_distance': 75},
      ),
      isFalse,
    );
    expect(discoveryFiltersEqual(null, null), isTrue);
  });
}
