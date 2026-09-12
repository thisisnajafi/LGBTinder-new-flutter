import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/utils/chat_keyboard_anchor.dart';
import 'package:lgbtindernew/widgets/chat/chat_keyboard_inset_pad.dart';

void main() {
  Widget host({
    required double inset,
    bool reduceMotion = false,
    ValueChanged<double>? onBottomInsetChanged,
    VoidCallback? onInsetTick,
    Widget? child,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, appChild) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewInsets: EdgeInsets.only(bottom: inset),
            disableAnimations: reduceMotion,
          ),
          child: appChild!,
        );
      },
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: ChatKeyboardInsetPad(
          onBottomInsetChanged: onBottomInsetChanged,
          onInsetTick: onInsetTick,
          child: child ?? const SizedBox.expand(),
        ),
      ),
    );
  }

  AnimatedPadding padOf(WidgetTester tester) {
    return tester.widget<AnimatedPadding>(
      find.byKey(const ValueKey('chat-keyboard-inset-pad')),
    );
  }

  testWidgets('pads viewInsets.bottom over transitionModal', (tester) async {
    final insets = <double>[];
    await tester.pumpWidget(host(inset: 0, onBottomInsetChanged: insets.add));
    expect(padOf(tester).padding, EdgeInsets.zero);
    expect(padOf(tester).duration, AppAnimations.transitionModal);
    expect(padOf(tester).curve, AppAnimations.curveDefault);

    await tester.pumpWidget(host(inset: 280, onBottomInsetChanged: insets.add));
    await tester.pump();
    expect(padOf(tester).padding, const EdgeInsets.only(bottom: 280));
    expect(insets, containsAll([0, 280]));
  });

  testWidgets('Reduce Motion snaps padding', (tester) async {
    await tester.pumpWidget(host(inset: 0, reduceMotion: true));
    await tester.pumpWidget(host(inset: 200, reduceMotion: true));
    await tester.pump();
    expect(padOf(tester).duration, Duration.zero);
    expect(padOf(tester).padding, const EdgeInsets.only(bottom: 200));
  });

  testWidgets('does not add a second inset on top of Scaffold', (tester) async {
    await tester.pumpWidget(host(inset: 120));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
    expect(padOf(tester).padding, const EdgeInsets.only(bottom: 120));
  });

  testWidgets('keeps a reverse list pinned at pixel 0 while inset animates',
      (tester) async {
    final controller = ScrollController();
    final anchor = ChatKeyboardAnchor();

    Widget thread(double inset) {
      return host(
        inset: inset,
        onBottomInsetChanged: (bottom) {
          anchor.shouldPinToBottom(insetBottom: bottom, nearBottom: true);
        },
        onInsetTick: () {
          if (!anchor.isPinned || !controller.hasClients) return;
          final pos = controller.position;
          final target = ChatKeyboardAnchor.pinnedExtent(pixels: pos.pixels);
          if (target != null) controller.jumpTo(target);
        },
        child: ListView(
          reverse: true,
          controller: controller,
          children: List<Widget>.generate(
            24,
            (i) => SizedBox(height: 48, child: Text('row $i')),
          ),
        ),
      );
    }

    await tester.pumpWidget(thread(0));
    await tester.pumpAndSettle();
    controller.jumpTo(0);

    await tester.pumpWidget(thread(280));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(controller.position.pixels, closeTo(0, 1));

    await tester.pumpAndSettle();
    expect(controller.position.pixels, closeTo(0, 1));
  });
}
