import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/presentation/widgets/self_destruct_viewer.dart';
import 'package:lgbtindernew/features/chat/utils/self_destruct_send.dart';
import 'package:lgbtindernew/widgets/chat/message_bubble.dart';
import 'package:lgbtindernew/core/widgets/optimized_image.dart';

Widget _wrap(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('sender self-destruct bubble shows flame duration, not the photo',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MessageBubble(
          message: 'file:///tmp/secret.jpg',
          isSent: true,
          messageType: 'disappearing_image',
          mediaUrl: 'file:///tmp/secret.jpg',
          expiresInSeconds: 10,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Waiting to be opened'), findsOneWidget);
    expect(find.text('10s'), findsOneWidget);
    expect(find.byType(OptimizedImage), findsNothing);
  });

  testWidgets('duration sheet offers 5 10 30 60 second pills', (tester) async {
    await tester.pumpWidget(
      _wrap(const SelfDestructDurationSheet()),
    );

    expect(find.text('5s'), findsOneWidget);
    expect(find.text('10s'), findsOneWidget);
    expect(find.text('30s'), findsOneWidget);
    expect(find.text('60s'), findsOneWidget);
  });

  testWidgets('receiver unopened copy matches spec and never shows the photo',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: 'secret',
          isSent: false,
          messageType: 'disappearing_image',
          mediaUrl: 'https://example.com/secret.jpg',
          expiresInSeconds: 10,
          onSelfDestructTap: () => tapped = true,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(SelfDestructSend.receiverUnopenedLabel(10)),
      findsOneWidget,
    );
    expect(find.byType(OptimizedImage), findsNothing);

    await tester.tap(find.text(SelfDestructSend.receiverUnopenedLabel(10)));
    expect(tapped, isTrue);
  });

  testWidgets('expired after viewing is Photo expired and not tappable',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: 'secret',
          isSent: false,
          messageType: 'disappearing_image',
          isExpired: true,
          viewedAt: DateTime(2026, 9, 11),
          onSelfDestructTap: () => tapped = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo expired'), findsOneWidget);
    expect(find.byType(IgnorePointer), findsWidgets);
    await tester.tap(find.text('Photo expired'), warnIfMissed: false);
    expect(tapped, isFalse);
  });

  testWidgets('expired never-viewed copy is Photo no longer available',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: 'secret',
          isSent: false,
          messageType: 'disappearing_image',
          isExpired: true,
          onSelfDestructTap: () => tapped = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo no longer available'), findsOneWidget);
    await tester.tap(find.text('Photo no longer available'), warnIfMissed: false);
    expect(tapped, isFalse);
  });

  testWidgets('expiry keeps the row and crossfades to expired copy',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MessageBubble(
          key: ValueKey('sd'),
          message: 'secret',
          isSent: false,
          messageId: 42,
          messageType: 'disappearing_image',
          expiresInSeconds: 10,
          onSelfDestructTap: _noop,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text(SelfDestructSend.receiverUnopenedLabel(10)),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          key: const ValueKey('sd'),
          message: 'secret',
          isSent: false,
          messageId: 42,
          messageType: 'disappearing_image',
          isExpired: true,
          viewedAt: DateTime(2026, 9, 11),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo expired'), findsOneWidget);
    expect(find.byType(MessageBubble), findsOneWidget);
  });

  testWidgets('self-destruct preview shows HH:mm inside the bubble',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: 'secret',
          isSent: true,
          messageType: 'disappearing_image',
          mediaUrl: 'file:///tmp/secret.jpg',
          expiresInSeconds: 10,
          timestamp: DateTime(2026, 9, 11, 9, 5),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Waiting to be opened'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
  });
}

void _noop() {}
