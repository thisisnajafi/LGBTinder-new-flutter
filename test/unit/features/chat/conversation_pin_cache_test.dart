import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/chat.dart';
import 'package:lgbtindernew/features/chat/providers/conversation_pin_cache_provider.dart';

void main() {
  group('ConversationPinCacheNotifier', () {
    test('seedFromChats loads pinned peer ids', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationPinCacheProvider.notifier).seedFromChats([
        Chat(id: 1, userId: 5, firstName: 'Alex', isPinned: true),
        Chat(id: 2, userId: 8, firstName: 'Sam', isPinned: false),
      ]);

      expect(container.read(conversationPinCacheProvider), {5});
    });

    test('setPinned updates cache', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationPinCacheProvider.notifier).setPinned(42, true);
      expect(container.read(conversationPinCacheProvider), {42});

      container.read(conversationPinCacheProvider.notifier).setPinned(42, false);
      expect(container.read(conversationPinCacheProvider), isEmpty);
    });
  });
}
