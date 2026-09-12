import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/incoming_call_banner.dart';

void main() {
  testWidgets('IncomingCallBanner builds without MediaQuery-in-initState crash',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: IncomingCallBanner(
              callData: IncomingCallData(
                callId: '1',
                callType: 'audio',
                callerId: 2,
                callerName: 'Test Caller',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(AppAnimations.incomingBanner);

    expect(tester.takeException(), isNull);
    expect(find.text('Test Caller'), findsOneWidget);
    expect(find.text('Incoming voice call'), findsOneWidget);
    expect(IncomingCallBanner.contentHeight, 80);
    expect(
      tester.getSize(find.byKey(const ValueKey('incoming-call-banner-body'))).height,
      IncomingCallBanner.contentHeight,
    );
  });
}
