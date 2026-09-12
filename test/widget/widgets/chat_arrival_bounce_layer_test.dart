import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';
import 'package:lgbtindernew/widgets/chat/chat_arrival_bounce_layer.dart';

void main() {
  testWidgets('play springs past the latest edge then settles', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ChatArrivalBounceLayer(
              peerUserId: 9,
              child: SizedBox(width: 80, height: 80, child: Text('thread')),
            ),
          ),
        ),
      ),
    );

    container.read(chatArrivalBounceProvider(9).notifier).play();
    await tester.pump();
    await tester.pump(AppAnimations.chatArrivalBounce * 0.4);

    final mid = tester.widget<Transform>(
      find.byKey(const ValueKey('chat-arrival-bounce')),
    );
    expect(mid.transform.getTranslation().y, greaterThan(0));

    await tester.pumpAndSettle();
    final end = tester.widget<Transform>(
      find.byKey(const ValueKey('chat-arrival-bounce')),
    );
    expect(end.transform.getTranslation().y, closeTo(0, 0.5));
  });

  testWidgets('Reduce Motion ignores the bounce token', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: const Scaffold(
            body: ChatArrivalBounceLayer(
              peerUserId: 9,
              child: SizedBox(width: 80, height: 80, child: Text('thread')),
            ),
          ),
        ),
      ),
    );

    container.read(chatArrivalBounceProvider(9).notifier).play();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('chat-arrival-bounce')),
    );
    expect(transform.transform.getTranslation().y, 0);
  });
}
