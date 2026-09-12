import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/widgets/chat/message_status_indicator.dart';

void main() {
  Widget host({
    required bool isDelivered,
    required bool isRead,
    MessageDeliveryStatus deliveryStatus = MessageDeliveryStatus.sent,
    int messageId = 1,
    VoidCallback? onRetry,
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      builder: reduceMotion
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
      home: Scaffold(
        body: Center(
          child: MessageStatusIndicator(
            isDelivered: isDelivered,
            isRead: isRead,
            deliveryStatus: deliveryStatus,
            messageId: messageId,
            onRetry: onRetry,
          ),
        ),
      ),
    );
  }

  double? pulseScale(WidgetTester tester) {
    final finder = find.byKey(const ValueKey('chat-status-tick-scale'));
    if (finder.evaluate().isEmpty) return null;
    return tester.widget<ScaleTransition>(finder).scale.value;
  }

  testWidgets('sent→delivered pulses 1.0→1.3→1.0 once', (tester) async {
    await tester.pumpWidget(host(isDelivered: false, isRead: false));
    expect(pulseScale(tester), 1.0);

    await tester.pumpWidget(host(isDelivered: true, isRead: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final mid = pulseScale(tester)!;
    expect(mid, greaterThan(1.0));
    expect(mid, lessThanOrEqualTo(AppAnimations.chatStatusTickScalePeak));

    await tester.pump(AppAnimations.chatStatusTickPulse);
    expect(pulseScale(tester), closeTo(1.0, 0.001));
  });

  testWidgets('history read does not pulse on first build', (tester) async {
    await tester.pumpWidget(host(isDelivered: true, isRead: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(pulseScale(tester), 1.0);
  });

  testWidgets('recycled row with a new messageId does not pulse',
      (tester) async {
    await tester.pumpWidget(
      host(isDelivered: false, isRead: false, messageId: 11),
    );
    await tester.pumpWidget(
      host(isDelivered: true, isRead: true, messageId: 22),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(pulseScale(tester), 1.0);
  });

  testWidgets('Reduce Motion skips scale and snaps color', (tester) async {
    await tester.pumpWidget(
      host(isDelivered: false, isRead: false, reduceMotion: true),
    );
    await tester.pumpWidget(
      host(isDelivered: true, isRead: true, reduceMotion: true),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('chat-status-tick-scale')),
      findsNothing,
    );

    final tween = tester.widget<TweenAnimationBuilder<Color?>>(
      find.byType(TweenAnimationBuilder<Color?>),
    );
    expect(tween.duration, Duration.zero);
    expect(
      (tween.tween as ColorTween).end,
      AppTheme.lightTheme.colorScheme.primary,
    );
  });

  testWidgets('failed refresh stays tappable for retry', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        isDelivered: false,
        isRead: false,
        deliveryStatus: MessageDeliveryStatus.failed,
        onRetry: () => taps++,
      ),
    );

    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      [AppIcons.refresh],
    );

    await tester.tap(find.byType(GestureDetector));
    expect(taps, 1);
  });

  testWidgets('sending and queued use the clock SVG', (tester) async {
    await tester.pumpWidget(
      host(
        isDelivered: false,
        isRead: false,
        deliveryStatus: MessageDeliveryStatus.sending,
      ),
    );
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      [AppIcons.clock],
    );
    expect(find.bySemanticsLabel('Sending message'), findsOneWidget);

    await tester.pumpWidget(
      host(
        isDelivered: false,
        isRead: false,
        deliveryStatus: MessageDeliveryStatus.queued,
      ),
    );
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      [AppIcons.clock],
    );
    expect(find.bySemanticsLabel('Message queued'), findsOneWidget);
  });

  testWidgets('check painter is isolated with RepaintBoundary', (tester) async {
    await tester.pumpWidget(host(isDelivered: false, isRead: false));

    expect(
      find.byKey(const ValueKey('chat-status-tick-paint')),
      findsOneWidget,
    );
  });
}
