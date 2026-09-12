import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_connect_transition.dart';

void main() {
  testWidgets('timer is hidden until connected then fades in', (tester) async {
    final connected = ValueNotifier(false);
    addTearDown(connected.dispose);

    await tester.pumpWidget(
      _host(connected),
    );

    expect(_opacity(tester, 'call-connect-timer'), 0);
    expect(find.byKey(const ValueKey('call-connect-pulse')), findsOneWidget);
    expect(_opacity(tester, 'call-connect-stage'), 0);

    connected.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacity(tester, 'call-connect-timer'), greaterThan(0));
    expect(_opacity(tester, 'call-connect-timer'), lessThan(1));

    await tester.pump(AppAnimations.callConnect);
    expect(_opacity(tester, 'call-connect-timer'), 1);
    expect(find.byKey(const ValueKey('call-connect-pulse')), findsNothing);
    expect(_opacity(tester, 'call-connect-stage'), 1);
  });

  testWidgets('Reduce Motion skips to the connected layout', (tester) async {
    final connected = ValueNotifier(false);
    addTearDown(connected.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: AnimatedBuilder(
          animation: connected,
          builder: (context, _) {
            return CallConnectHost(
              connected: connected.value,
              child: const _ConnectDemo(),
            );
          },
        ),
      ),
    );

    connected.value = true;
    await tester.pump();

    expect(_opacity(tester, 'call-connect-timer'), 1);
    expect(find.byKey(const ValueKey('call-connect-pulse')), findsNothing);
    expect(_opacity(tester, 'call-connect-stage'), 1);
  });

  testWidgets('already connected first frame skips the transition',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CallConnectHost(
          connected: true,
          child: _ConnectDemo(),
        ),
      ),
    );

    expect(_opacity(tester, 'call-connect-timer'), 1);
    expect(find.byKey(const ValueKey('call-connect-pulse')), findsNothing);
    expect(_opacity(tester, 'call-connect-stage'), 1);
  });
}

Widget _host(ValueNotifier<bool> connected) {
  return MaterialApp(
    home: AnimatedBuilder(
      animation: connected,
      builder: (context, _) {
        return CallConnectHost(
          connected: connected.value,
          child: const _ConnectDemo(),
        );
      },
    ),
  );
}

double _opacity(WidgetTester tester, String key) {
  return tester.widget<Opacity>(find.byKey(ValueKey(key))).opacity;
}

class _ConnectDemo extends StatelessWidget {
  const _ConnectDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CallConnectTimer(child: Text('00:00')),
        CallConnectPulse(child: Text('pulse')),
        CallConnectStage(child: Text('stage')),
      ],
    );
  }
}
