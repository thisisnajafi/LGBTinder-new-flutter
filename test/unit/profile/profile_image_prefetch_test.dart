import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/profile/utils/profile_image_prefetch.dart';

void main() {
  test('adjacentUrls includes current, previous, and next', () {
    expect(
      ProfileImagePrefetch.adjacentUrls(
        const ['a.jpg', 'b.jpg', 'c.jpg'],
        1,
      ),
      ['b.jpg', 'a.jpg', 'c.jpg'],
    );
  });

  test('adjacentUrls at the ends skips missing neighbors', () {
    expect(
      ProfileImagePrefetch.adjacentUrls(const ['a.jpg', 'b.jpg'], 0),
      ['a.jpg', 'b.jpg'],
    );
    expect(
      ProfileImagePrefetch.adjacentUrls(const ['a.jpg', 'b.jpg'], 1),
      ['b.jpg', 'a.jpg'],
    );
  });

  test('adjacentUrls skips blanks and duplicates', () {
    expect(
      ProfileImagePrefetch.adjacentUrls(const ['a.jpg', '', 'a.jpg'], 0),
      ['a.jpg'],
    );
    expect(ProfileImagePrefetch.adjacentUrls(const [], 0), isEmpty);
  });
}
