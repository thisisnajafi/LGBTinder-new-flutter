import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/widgets/profile/edit/profile_edit_bio_field.dart';

void main() {
  testWidgets('bio field writes through the controller without rebuilding parent',
      (tester) async {
    final controller = TextEditingController();
    var parentBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return ProfileEditBioField(controller: controller);
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.enterText(find.byType(TextField), 'Hello from edit');
    await tester.pump();

    expect(controller.text, 'Hello from edit');
    expect(parentBuilds, buildsAfterFirstFrame);
    expect(find.byKey(ProfileEditBioField.fieldKey), findsOneWidget);
  });
}
