import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/notifications/providers/notification_providers.dart';

void main() {
  test('seeded unread count of 0 hides the notification badge number', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(unreadNotificationCountSeedProvider.notifier).state = 4;
    expect(await container.read(unreadNotificationCountProvider.future), 4);

    container.read(unreadNotificationCountSeedProvider.notifier).state = 0;
    expect(await container.read(unreadNotificationCountProvider.future), 0);
  });
}
