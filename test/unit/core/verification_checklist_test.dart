import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/utils/display_refresh.dart';
import 'package:lgbtindernew/core/widgets/staggered_list_item.dart';
import 'package:lgbtindernew/features/chat/data/local/app_database.dart';
import 'package:lgbtindernew/features/chat/data/local/chat_local_repository.dart';
import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_scroll.dart';
import 'package:lgbtindernew/features/chat/utils/chat_unseen_incoming.dart';
import 'package:lgbtindernew/features/chat/utils/voice_waveform_layout.dart';
import 'package:lgbtindernew/pages/home_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/shared/services/notification_navigation.dart';
import 'package:lgbtindernew/widgets/animations/lottie_animations.dart';
import 'package:lgbtindernew/widgets/chat/message_input.dart';

void main() {
  group('plan verification checklist', () {
    testWidgets('rapid send 20 times does not drop or double-fire',
        (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageInput(
                celebrateSend: false,
                onSend: sent.add,
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < 20; i++) {
        await tester.enterText(find.byType(TextField), 'msg $i');
        await tester.pump();
        await tester.tap(find.byTooltip('Send message'));
        await tester.pump();
      }

      expect(sent, [
        for (var i = 0; i < 20; i++) 'msg $i',
      ]);
      expect(tester.takeException(), isNull);
    });

    test('incoming while scrolled up increments badge instead of jumping', () {
      expect(ChatThreadScroll.isNearLatest(pixels: 400), isFalse);
      expect(ChatUnseenIncoming.shouldShowFab(pixels: 400), isTrue);
      expect(
        ChatUnseenIncoming.shouldIncrementBadge(
          insertedNewRow: true,
          fromPeer: true,
          nearBottom: false,
        ),
        isTrue,
      );
      expect(
        ChatUnseenIncoming.shouldIncrementBadge(
          insertedNewRow: true,
          fromPeer: true,
          nearBottom: true,
        ),
        isFalse,
      );
    });

    test('ten home-tab switches never keep all idle tabs mounted', () {
      var mounted = <int>{0};
      for (var i = 0; i < 10; i++) {
        final tab = i % 5;
        mounted.add(tab);
        mounted = homeTabsAfterIdleDispose(
          mounted: mounted,
          currentIndex: tab,
        );
        expect(mounted.contains(tab), isTrue);
        expect(mounted.length, lessThan(5));
      }
    });

    test('message notification opens the chat thread', () {
      expect(
        NotificationNavigation.resolveDestination(
          type: 'message',
          data: {'user_id': 5},
        ),
        Uri(path: AppRoutes.chat, queryParameters: {'userId': '5'}).toString(),
      );
    });

    test('offline Drift cache returns stored history', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final repo = ChatLocalRepository(db);
      await repo.upsertMessages(
        [
          Message(
            id: 11,
            senderId: 2,
            receiverId: 1,
            message: 'cached hello',
            createdAt: DateTime.utc(2026, 9, 15),
          ),
        ],
        2,
      );
      final rows = await repo.getMessagesForOtherUser(2);
      expect(rows.single.message, 'cached hello');
    });

    testWidgets('Reduce Motion skips stagger and Lottie playback',
        (tester) async {
      LottiePlaybackLimiter.debugReset();
      addTearDown(LottiePlaybackLimiter.debugReset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: const Column(
            children: [
              StaggeredListItem(
                index: 0,
                animateAppear: true,
                child: Text('Row'),
              ),
              ThemeAwareLottie(
                assetPath: 'assets/lottie/chat_heart.json',
                width: 48,
                height: 48,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.text('Row'));
      expect(AppAnimations.animationsEnabled(context), isFalse);
      expect(
        find.descendant(
          of: find.byType(StaggeredListItem),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
      expect(find.byType(LottieBuilder), findsNothing);
      expect(LottiePlaybackLimiter.debugActiveCount, 0);
    });

    test('voice waveform ticks are gated so scroll paints stay cheap', () {
      final gate = ChatVoicePositionGate();
      final t0 = DateTime.utc(2026, 9, 15);
      expect(gate.allow(t0), isTrue);
      expect(gate.allow(t0.add(const Duration(milliseconds: 99))), isFalse);
      expect(gate.allow(t0.add(const Duration(milliseconds: 100))), isTrue);
    });

    testWidgets('display refresh probe is readable without a 120Hz device',
        (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      expect(displayRefreshRateHz(), greaterThanOrEqualTo(0));
    });
  });
}
