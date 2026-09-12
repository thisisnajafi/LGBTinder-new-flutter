import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/data/models/call_end_summary.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_end_overlay.dart';

void main() {
  testWidgets('connected summary shows duration then pops after hold',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CallEndOverlay(
          summary: const CallEndSummary(
            reason: CallEndReason.ended,
            talkTime: Duration(minutes: 1, seconds: 2),
            isVideo: true,
            wasConnected: true,
          ),
          onFinished: () => finished++,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(AppAnimations.callEndFade);

    expect(find.byKey(const ValueKey('call-end-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('call-end-duration')), findsOneWidget);
    expect(find.text('Call ended'), findsOneWidget);
    expect(find.text('1 minute 2 seconds'), findsOneWidget);
    expect(finished, 0);

    await tester.pump(AppAnimations.callEndHold);
    expect(finished, 1);
  });

  testWidgets('Reduce Motion skips fade and pops after 1s', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: CallEndOverlay(
          summary: const CallEndSummary(
            reason: CallEndReason.declined,
            talkTime: Duration.zero,
            isVideo: false,
            wasConnected: false,
          ),
          onFinished: () => finished++,
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Call declined'), findsOneWidget);
    expect(find.byKey(const ValueKey('call-end-duration')), findsNothing);
    expect(finished, 0);

    await tester.pump(AppAnimations.callEndHoldReduced);
    expect(finished, 1);
  });
}
