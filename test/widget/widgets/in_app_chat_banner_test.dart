import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/chat/providers/in_app_chat_banner_provider.dart';
import 'package:lgbtindernew/features/chat/utils/in_app_chat_banner.dart';
import 'package:lgbtindernew/widgets/chat/in_app_chat_banner.dart';

void main() {
  const alex = InAppChatBannerItem(
    id: '1',
    peerUserId: 42,
    title: 'Alex',
    body: 'Hello there',
  );

  Future<ProviderContainer> pumpHost(
    WidgetTester tester, {
    Duration autoDismiss = const Duration(days: 1),
  }) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inAppChatBannerProvider.overrideWith(
            () => InAppChatBannerNotifier(autoDismiss: autoDismiss),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(
                  body: InAppChatBannerHost(child: SizedBox.expand()),
                ),
              );
            },
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('shows title and body at 72px', (tester) async {
    final container = await pumpHost(tester);
    container.read(inAppChatBannerProvider.notifier).show(alex);
    await tester.pump();
    await tester.pump(AppAnimations.incomingBanner);

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Hello there'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('in-app-chat-banner-body-1'))).height,
      InAppChatMessageBanner.height,
    );
  });

  testWidgets('tap opens callback and dismisses', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: InAppChatMessageBanner(
                item: alex,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(AppAnimations.incomingBanner);
    await tester.tap(find.text('Hello there'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('swipe up dismisses', (tester) async {
    final container = await pumpHost(tester);
    container.read(inAppChatBannerProvider.notifier).show(alex);
    await tester.pump();
    await tester.pump(AppAnimations.incomingBanner);

    await tester.fling(find.text('Hello there'), const Offset(0, -120), 800);
    await tester.pump();

    expect(find.text('Hello there'), findsNothing);
    expect(container.read(inAppChatBannerProvider), isEmpty);
  });

  testWidgets('auto-dismisses after hold', (tester) async {
    final container = await pumpHost(
      tester,
      autoDismiss: const Duration(milliseconds: 80),
    );
    container.read(inAppChatBannerProvider.notifier).show(alex);
    await tester.pump();
    expect(find.text('Alex'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('Alex'), findsNothing);
  });

  testWidgets('stacks at most two banners', (tester) async {
    final container = await pumpHost(tester);
    final notifier = container.read(inAppChatBannerProvider.notifier);
    notifier.show(alex);
    notifier.show(
      const InAppChatBannerItem(
        id: '2',
        peerUserId: 7,
        title: 'Sam',
        body: 'Photo',
      ),
    );
    notifier.show(
      const InAppChatBannerItem(
        id: '3',
        peerUserId: 9,
        title: 'Riley',
        body: 'Hey',
      ),
    );
    await tester.pump();

    expect(find.text('Alex'), findsNothing);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Riley'), findsOneWidget);
  });
}
