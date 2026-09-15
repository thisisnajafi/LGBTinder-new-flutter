import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/profile/presentation/widgets/expandable_profile_bio.dart';

void main() {
  testWidgets('Read more expands without rebuilding a parent marker',
      (tester) async {
    var parentBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return const ExpandableProfileBio(
                text:
                    'This bio is long enough to collapse so we can tap Read more '
                    'and keep the parent Builder from rebuilding on expand. '
                    'Padding padding padding padding padding.',
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Read more'), findsOneWidget);
    final buildsBefore = parentBuilds;
    await tester.tap(find.text('Read more'));
    await tester.pump();
    expect(find.text('Read less'), findsOneWidget);
    expect(parentBuilds, buildsBefore);
  });

  testWidgets('short bios skip the collapse control', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpandableProfileBio(text: 'Short bio'),
        ),
      ),
    );

    expect(find.text('Read more'), findsNothing);
    expect(find.text('Short bio'), findsOneWidget);
  });
}
