import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/widgets/chat/chat_message_enter_animation.dart';

const _slideKey = ValueKey('chat-message-enter-slide');
const _fadeKey = ValueKey('chat-message-enter-fade');
const _scaleKey = ValueKey('chat-message-enter-scale');

void main() {
  test('send enter uses Telegram composer offset and 220ms', () {
    expect(AppAnimations.chatMessageSend, const Duration(milliseconds: 220));
    expect(AppAnimations.chatMessageSendSlide, const Offset(0.15, 0.3));
    expect(AppAnimations.chatMessageSendScaleBegin, 0.85);
    expect(AppAnimations.curveDefault, Curves.easeOutCubic);
  });

  test('receive enter uses Telegram left offset and 260ms easeOutBack', () {
    expect(
      AppAnimations.chatMessageReceive,
      const Duration(milliseconds: 260),
    );
    expect(AppAnimations.chatMessageReceiveSlide, const Offset(-0.15, 0.1));
    expect(AppAnimations.chatMessageReceiveCurve, Curves.easeOutBack);
  });

  testWidgets('outgoing enter slides, fades, and scales then settles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageEnterAnimation(
            play: true,
            isSent: true,
            child: Text('hi'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<SlideTransition>(find.byKey(_slideKey)).position.value,
      AppAnimations.chatMessageSendSlide,
    );
    expect(
      tester.widget<FadeTransition>(find.byKey(_fadeKey)).opacity.value,
      0,
    );
    expect(
      tester.widget<ScaleTransition>(find.byKey(_scaleKey)).scale.value,
      AppAnimations.chatMessageSendScaleBegin,
    );
    expect(
      tester.widget<ScaleTransition>(find.byKey(_scaleKey)).alignment,
      Alignment.centerRight,
    );

    await tester.pump(AppAnimations.chatMessageSend);
    expect(
      tester.widget<SlideTransition>(find.byKey(_slideKey)).position.value,
      Offset.zero,
    );
    expect(
      tester.widget<FadeTransition>(find.byKey(_fadeKey)).opacity.value,
      1,
    );
    expect(
      tester.widget<ScaleTransition>(find.byKey(_scaleKey)).scale.value,
      1,
    );
  });

  testWidgets('history play:false is already settled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageEnterAnimation(
            play: false,
            isSent: true,
            child: Text('old'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<SlideTransition>(find.byKey(_slideKey)).position.value,
      Offset.zero,
    );
    expect(
      tester.widget<FadeTransition>(find.byKey(_fadeKey)).opacity.value,
      1,
    );
    expect(
      tester.widget<ScaleTransition>(find.byKey(_scaleKey)).scale.value,
      1,
    );
  });

  testWidgets('incoming enter slides from the left then settles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageEnterAnimation(
            play: true,
            isSent: false,
            child: Text('hey'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<SlideTransition>(find.byKey(_slideKey)).position.value,
      AppAnimations.chatMessageReceiveSlide,
    );
    expect(
      tester.widget<FadeTransition>(find.byKey(_fadeKey)).opacity.value,
      0,
    );
    expect(find.byKey(_scaleKey), findsNothing);

    await tester.pump(AppAnimations.chatMessageReceive);
    expect(
      tester.widget<SlideTransition>(find.byKey(_slideKey)).position.value,
      Offset.zero,
    );
    expect(
      tester.widget<FadeTransition>(find.byKey(_fadeKey)).opacity.value,
      1,
    );
  });

  testWidgets('Reduce Motion skips the send animation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: ChatMessageEnterAnimation(
            play: true,
            isSent: true,
            child: Text('hi'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<SlideTransition>(find.byKey(_slideKey)).position.value,
      Offset.zero,
    );
    expect(
      tester.widget<FadeTransition>(find.byKey(_fadeKey)).opacity.value,
      1,
    );
    expect(
      tester.widget<ScaleTransition>(find.byKey(_scaleKey)).scale.value,
      1,
    );
  });

  testWidgets('Reduce Motion skips the receive animation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: ChatMessageEnterAnimation(
            play: true,
            isSent: false,
            child: Text('hey'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<SlideTransition>(find.byKey(_slideKey)).position.value,
      Offset.zero,
    );
    expect(
      tester.widget<FadeTransition>(find.byKey(_fadeKey)).opacity.value,
      1,
    );
  });
}
