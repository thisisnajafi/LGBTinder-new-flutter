import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/utils/chat_outbox_ui.dart';
import 'package:lgbtindernew/widgets/chat/chat_outbox_banner.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required bool visible,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: ChatOutboxBanner(
                peerUserId: 9,
                visibleOverride: visible,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows Sending queued… with the clock SVG', (tester) async {
    await pumpBanner(tester, visible: true);

    expect(find.text(ChatOutboxUi.sendingQueuedLabel), findsOneWidget);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      [AppIcons.clock],
    );
  });

  testWidgets('hides when the outbox is empty', (tester) async {
    await pumpBanner(tester, visible: false);

    expect(find.text(ChatOutboxUi.sendingQueuedLabel), findsNothing);
  });
}
