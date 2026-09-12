import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_hud.dart';

void main() {
  testWidgets('video HUD hides after idle and returns on stage tap',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CallHudHost(
            autoHide: true,
            child: _HudDemo(),
          ),
        ),
      ),
    );

    expect(_hudOpacity(tester), 1);

    await tester.pump(AppAnimations.callHudIdle);
    expect(_hudOpacity(tester), 0);

    await tester.tap(find.byKey(const ValueKey('call-hud-stage')));
    await tester.pump();
    expect(_hudOpacity(tester), 1);
    expect(find.text('End'), findsOneWidget);
  });

  testWidgets('voice HUD stays visible after idle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CallHudHost(
            autoHide: false,
            child: _HudDemo(),
          ),
        ),
      ),
    );

    await tester.pump(AppAnimations.callHudIdle);
    expect(_hudOpacity(tester), 1);
  });
}

double _hudOpacity(WidgetTester tester) {
  return tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
}

class _HudDemo extends StatelessWidget {
  const _HudDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            key: const ValueKey('call-hud-stage'),
            behavior: HitTestBehavior.opaque,
            onTap: () => CallHudController.maybeOf(context)?.reveal(),
            child: const SizedBox.expand(),
          ),
        ),
        CallHudFade(
          child: TextButton(
            onPressed: () {},
            child: const Text('End'),
          ),
        ),
      ],
    );
  }
}
