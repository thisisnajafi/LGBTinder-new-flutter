import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/marketing/presentation/widgets/badge_popup_queue.dart';
import 'package:lgbtindernew/features/marketing/presentation/widgets/daily_rewards_dialog.dart';

void main() {
  setUp(BadgePopupQueue.debugReset);

  test('badge popup queue runs one task after another', () async {
    final order = <int>[];
    final first = BadgePopupQueue.enqueue(() async {
      order.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      order.add(2);
    });
    final second = BadgePopupQueue.enqueue(() async {
      order.add(3);
    });

    await Future.wait([first, second]);
    expect(order, [1, 2, 3]);
  });

  test('only today loads reward artwork', () {
    expect(DailyRewardsDialog.shouldShowRewardArtwork(isToday: true), isTrue);
    expect(DailyRewardsDialog.shouldShowRewardArtwork(isToday: false), isFalse);
    expect(DailyRewardsDialog.isNetworkIcon('https://cdn.example/icon.png'), isTrue);
    expect(DailyRewardsDialog.isNetworkIcon('gift'), isFalse);
  });
}
