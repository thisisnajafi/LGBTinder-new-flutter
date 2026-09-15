import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/widgets/match_interaction/animated_snackbar.dart';

void main() {
  testWidgets('snackbar overlay does not eat full-screen taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => tapped = true,
              behavior: HitTestBehavior.opaque,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('Body'),
                ),
              ),
            ),
            floatingActionButton: Builder(
              builder: (context) {
                return FloatingActionButton(
                  onPressed: () {
                    AnimatedSnackbar.show(context, message: 'Saved');
                  },
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Body'));
    expect(tapped, isTrue);
  });

  testWidgets('Reduce Motion skips snackbar slide', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      AnimatedSnackbar.show(context, message: 'Saved');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(Align),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    expect(find.text('Saved'), findsOneWidget);
  });
}
