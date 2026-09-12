import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/providers/chat_list_hidden_peers_provider.dart';

void main() {
  test('hide then undo restore keeps the peer out of the hidden set', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(chatListHiddenPeersProvider.notifier).hide(7);
    expect(container.read(chatListHiddenPeersProvider), {7});

    container.read(chatListHiddenPeersProvider.notifier).restore(7);
    expect(container.read(chatListHiddenPeersProvider), isEmpty);
  });

  test('invalid ids are ignored', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(chatListHiddenPeersProvider.notifier).hide(0);
    expect(container.read(chatListHiddenPeersProvider), isEmpty);
  });
}
