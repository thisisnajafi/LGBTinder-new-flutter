import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/widgets/profile_image_widget.dart';

void main() {
  testWidgets('ProfileImageWidget does not crash with infinite constraints',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SizedBox.expand(
            child: ProfileImageWidget(
              imageUrl: null,
              userId: 7,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ProfileImageWidget), findsOneWidget);
  });
}
