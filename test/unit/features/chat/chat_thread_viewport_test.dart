import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';

void main() {
  test('viewport hides the FAB at bottom and tracks unseen incoming', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(chatThreadViewportProvider(4).notifier);

    expect(container.read(chatThreadViewportProvider(4)).showFab, isFalse);
    expect(container.read(chatThreadViewportProvider(4)).unseenCount, 0);
    expect(container.read(isAtBottomProvider(4)), isTrue);

    notifier.applyScroll(showFab: true, atBottom: false);
    notifier.incrementUnseen();
    notifier.incrementUnseen();
    expect(container.read(chatThreadViewportProvider(4)).showFab, isTrue);
    expect(container.read(chatThreadViewportProvider(4)).unseenCount, 2);
    expect(container.read(isAtBottomProvider(4)), isFalse);

    notifier.applyScroll(showFab: false, atBottom: true);
    expect(container.read(chatThreadViewportProvider(4)).showFab, isFalse);
    expect(container.read(chatThreadViewportProvider(4)).unseenCount, 0);
    expect(container.read(isAtBottomProvider(4)), isTrue);

    notifier.incrementUnseen();
    expect(container.read(chatThreadViewportProvider(4)).unseenCount, 1);
    notifier.clearUnseen();
    expect(container.read(chatThreadViewportProvider(4)).showFab, isFalse);
    expect(container.read(chatThreadViewportProvider(4)).unseenCount, 0);
  });
}
