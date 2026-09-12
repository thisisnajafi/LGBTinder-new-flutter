import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/widgets/discovery/filter_widgets.dart';

void main() {
  testWidgets('age slider drag does not rebuild the parent', (tester) async {
    var parentBuilds = 0;
    final age = ValueNotifier(const RangeValues(18, 35));
    addTearDown(age.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return FilterAgeRangeControl(values: age);
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.drag(find.byType(RangeSlider), const Offset(80, 0));
    await tester.pump();

    expect(parentBuilds, buildsAfterFirstFrame);
    expect(age.value, isNot(const RangeValues(18, 35)));
  });

  testWidgets('distance slider drag does not rebuild the parent', (tester) async {
    var parentBuilds = 0;
    final distance = ValueNotifier(50.0);
    addTearDown(distance.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              parentBuilds++;
              return FilterDistanceControl(distance: distance);
            },
          ),
        ),
      ),
    );

    final buildsAfterFirstFrame = parentBuilds;
    await tester.drag(find.byType(Slider), const Offset(80, 0));
    await tester.pump();

    expect(parentBuilds, buildsAfterFirstFrame);
    expect(distance.value, isNot(50.0));
  });
}
