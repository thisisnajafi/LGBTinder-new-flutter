import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/widgets/profile/avatar_upload.dart';
import 'package:lgbtindernew/widgets/profile/edit/profile_edit_bio_field.dart';
import 'package:lgbtindernew/widgets/profile/edit/profile_edit_photos_section.dart';
import 'package:lgbtindernew/widgets/profile/edit/profile_image_editor.dart';

void main() {
  testWidgets('ProfileEditPhotosSection shows avatar and gallery editor',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileEditPhotosSection(
                initialImages: [],
                name: 'Alex',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Profile photo'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.byType(AvatarUpload), findsOneWidget);
    expect(find.byType(ProfileImageEditor), findsOneWidget);
    expect(find.byKey(ProfileEditPhotosSection.sectionKey), findsOneWidget);
  });

  testWidgets('ProfileEditBioField types without a parent setState',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProfileEditBioField(controller: controller),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(ProfileEditBioField.fieldKey),
      'Hello from bio',
    );
    await tester.pump();

    expect(controller.text, 'Hello from bio');
    expect(find.text('Hello from bio'), findsOneWidget);
  });
}
