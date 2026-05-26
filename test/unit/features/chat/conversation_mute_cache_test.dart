import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/chat.dart';
import 'package:lgbtindernew/features/chat/providers/conversation_mute_cache_provider.dart';

void main() {
  group('ConversationMuteCacheNotifier', () {
    test('seedFromChats loads muted peer ids', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationMuteCacheProvider.notifier).seedFromChats([
        Chat(id: 1, userId: 5, firstName: 'Alex', isMuted: true),
        Chat(id: 2, userId: 8, firstName: 'Sam', isMuted: false),
      ]);

      expect(container.read(conversationMuteCacheProvider), {5});
    });

    test('setMuted updates cache and bridge', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationMuteCacheProvider.notifier).setMuted(42, true);
      expect(container.read(conversationMuteCacheProvider), {42});
      expect(ConversationMuteBridge.isPeerMuted?.call(42), isTrue);
      expect(ConversationMuteBridge.isPeerMuted?.call(1), isFalse);

      container.read(conversationMuteCacheProvider.notifier).setMuted(42, false);
      expect(container.read(conversationMuteCacheProvider), isEmpty);
    });
  });
}
