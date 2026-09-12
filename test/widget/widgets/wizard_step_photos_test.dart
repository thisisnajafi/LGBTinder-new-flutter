import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/profile/providers/profile_wizard_provider.dart';
import 'package:lgbtindernew/widgets/profile/avatar_upload.dart';
import 'package:lgbtindernew/widgets/profile/wizard/wizard_step_photos.dart';

void main() {
  testWidgets('WizardStepPhotos shows add-photo copy when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: WizardStepPhotos(onPickPhoto: _noop)),
        ),
      ),
    );

    expect(find.text('Add a profile photo'), findsOneWidget);
    expect(find.byType(AvatarUpload), findsOneWidget);
  });

  testWidgets('WizardStepPhotos shows ready status when a photo exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileWizardProvider.overrideWith((ref) {
            final notifier = ProfileWizardNotifier();
            notifier.apply(
              const ProfileWizardState(
                avatarUrl: 'https://example.com/a.jpg',
                name: 'Alex',
              ),
            );
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WizardStepPhotos(onPickPhoto: _noop)),
        ),
      ),
    );

    expect(find.text('Looking good!'), findsOneWidget);
    expect(find.text('Profile photo selected'), findsOneWidget);
  });
}

void _noop() {}
