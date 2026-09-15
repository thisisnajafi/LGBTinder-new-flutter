import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/widgets/premium/upgrade_dialog.dart';

void main() {
  testWidgets('upgrade dialog uses a solid scrim with no BackdropFilter',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => UpgradeDialog.showFeatureLockedDialog(
                context,
                'Rewind',
              ),
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(UpgradeDialog), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('Rewind is a premium feature.'), findsOneWidget);
  });
}
