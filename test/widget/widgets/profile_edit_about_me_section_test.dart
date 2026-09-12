import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/widgets/profile/edit/profile_edit_about_me_section.dart';

void main() {
  testWidgets('lifestyle toggles update values without a parent setState',
      (tester) async {
    final values = ProfileEditAboutMeValues(
      height: 170,
      weight: 70,
      smoke: false,
    );
    var parentBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                parentBuilds++;
                return ProfileEditAboutMeSection(values: values);
              },
            ),
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.tap(find.text('Smoking'));
    await tester.pump();

    expect(values.smoke, isTrue);
    expect(parentBuilds, buildsAfterFirstFrame);
    expect(find.byKey(ProfileEditAboutMeSection.sectionKey), findsOneWidget);
  });
}
