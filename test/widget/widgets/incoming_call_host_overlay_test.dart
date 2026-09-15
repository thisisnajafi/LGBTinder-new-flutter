import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/incoming_call_banner.dart';
import 'package:lgbtindernew/features/calls/providers/incoming_call_provider.dart';

void main() {
  testWidgets('incoming overlay does not rebuild the host child', (tester) async {
    var childBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        incomingCallProvider.overrideWith(_SeedIncoming.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: IncomingCallHost(
            child: Builder(
              builder: (context) {
                childBuilds++;
                return const Text('App body');
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('App body'), findsOneWidget);
    final buildsBefore = childBuilds;

    (container.read(incomingCallProvider.notifier) as _SeedIncoming)
        .showTestCall();
    await tester.pump();
    await tester.pump(AppAnimations.incomingBanner);

    expect(find.text('Test Caller'), findsOneWidget);
    expect(find.text('App body'), findsOneWidget);
    expect(childBuilds, buildsBefore);
  });
}

class _SeedIncoming extends IncomingCallNotifier {
  @override
  IncomingCallData? build() => null;

  @override
  bool get isAppForeground => true;

  void showTestCall() {
    state = const IncomingCallData(
      callId: '1',
      callType: 'audio',
      callerId: 2,
      callerName: 'Test Caller',
    );
  }
}
