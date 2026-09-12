import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/pages/profile_wizard_page.dart';
import 'package:lgbtindernew/widgets/profile/wizard/wizard_step_photos.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('wizard step 1 is wrapped in a RepaintBoundary', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProfileWizardPage()),
      ),
    );
    await waitForAsync(tester);

    expect(find.byType(ProfileWizardPage), findsOneWidget);
    expect(find.byKey(WizardStepPhotos.pageKey), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(WizardStepPhotos),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });
}
