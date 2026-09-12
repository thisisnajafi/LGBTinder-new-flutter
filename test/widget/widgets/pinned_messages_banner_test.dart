import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/chat/pinned_messages_banner.dart';

void main() {
  testWidgets('hidden bar is 0px then opens to 48px', (tester) async {
    var count = 0;
    late void Function(void Function()) setCount;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setCount = setState;
              return PinnedMessagesBanner(pinnedCount: count, preview: 'hello');
            },
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(PinnedMessagesBanner.barKey)).height, 0);

    setCount(() => count = 1);
    await tester.pump();
    await tester.pump(AppAnimations.chatPinnedBanner);
    expect(
      tester.getSize(find.byKey(PinnedMessagesBanner.barKey)).height,
      AppAnimations.chatPinnedBannerHeight,
    );
    expect(find.text('hello'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('Reduce Motion opens the bar immediately', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: PinnedMessagesBanner(pinnedCount: 1, preview: 'pinned'),
        ),
      ),
    );
    expect(
      tester.widget<AnimatedContainer>(find.byKey(PinnedMessagesBanner.barKey)).duration,
      Duration.zero,
    );
    expect(find.text('pinned'), findsOneWidget);
  });
}
