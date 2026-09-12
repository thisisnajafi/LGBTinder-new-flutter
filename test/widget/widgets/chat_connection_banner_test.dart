import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/utils/chat_connection_ui.dart';
import 'package:lgbtindernew/widgets/chat/chat_connection_banner.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required ChatConnectionBannerKind kind,
    VoidCallback? onReconnect,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: ChatConnectionBanner(
                kindOverride: kind,
                showDelay: Duration.zero,
                onReconnect: onReconnect,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Connecting… copy is visible', (tester) async {
    await pumpBanner(tester, kind: ChatConnectionBannerKind.connecting);
    expect(find.text('Connecting…'), findsOneWidget);
    expect(find.text('Tap to reconnect'), findsNothing);
  });

  testWidgets('Waiting for network copy is visible', (tester) async {
    await pumpBanner(tester, kind: ChatConnectionBannerKind.waitingForNetwork);
    expect(find.text('Waiting for network'), findsOneWidget);
  });

  testWidgets('hidden kind renders no label', (tester) async {
    await pumpBanner(tester, kind: ChatConnectionBannerKind.hidden);
    expect(find.text('Connecting…'), findsNothing);
    expect(find.text('Tap to reconnect'), findsNothing);
    expect(find.text('Waiting for network'), findsNothing);
  });

  testWidgets('Tap to reconnect fires onReconnect', (tester) async {
    var taps = 0;
    await pumpBanner(
      tester,
      kind: ChatConnectionBannerKind.tapToReconnect,
      onReconnect: () => taps++,
    );
    expect(find.text('Tap to reconnect'), findsOneWidget);
    await tester.tap(find.text('Tap to reconnect'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('Connecting… is not tappable', (tester) async {
    var taps = 0;
    await pumpBanner(
      tester,
      kind: ChatConnectionBannerKind.connecting,
      onReconnect: () => taps++,
    );
    await tester.tap(find.text('Connecting…'));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('Sending queued… copy is visible', (tester) async {
    await pumpBanner(tester, kind: ChatConnectionBannerKind.sendingQueued);
    expect(find.text('Sending queued…'), findsOneWidget);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      [AppIcons.clock],
    );
  });
}
