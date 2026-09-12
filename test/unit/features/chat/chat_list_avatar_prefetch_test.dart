import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_list_avatar_prefetch.dart';

void main() {
  test('topUrls keeps the first 20 unique resolved avatars', () {
    final avatars = <String?>[
      '',
      null,
      'https://cdn.example/a.jpg',
      'https://cdn.example/a.jpg',
      for (var i = 1; i <= 25; i++) 'https://cdn.example/$i.jpg',
    ];

    final urls = ChatListAvatarPrefetch.topUrls(avatars);

    expect(urls.length, ChatListAvatarPrefetch.topCount);
    expect(urls.first, 'https://cdn.example/a.jpg');
    expect(urls, isNot(contains('https://cdn.example/25.jpg')));
  });

  test('topUrls respects a custom limit', () {
    expect(
      ChatListAvatarPrefetch.topUrls([
        'https://cdn.example/1.jpg',
        'https://cdn.example/2.jpg',
        'https://cdn.example/3.jpg',
      ], limit: 2),
      ['https://cdn.example/1.jpg', 'https://cdn.example/2.jpg'],
    );
  });
}
