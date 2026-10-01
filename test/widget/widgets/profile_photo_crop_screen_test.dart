import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/buttons/gradient_button.dart';
import 'package:lgbtindernew/widgets/profile/profile_photo_crop_screen.dart';

void main() {
  testWidgets('crop screen shows square crop chrome in light and dark', (
    tester,
  ) async {
    final missing = File('missing-profile-crop.png');

    Future<void> pumpTheme(ThemeData theme) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: ProfilePhotoCropScreen(imageFile: missing),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpTheme(AppTheme.lightTheme);
    expect(find.byKey(ProfilePhotoCropScreen.titleKey), findsOneWidget);
    expect(find.text('Square 1:1 for your profile'), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
    expect(find.bySemanticsLabel('Rotate photo'), findsOneWidget);
    expect(find.bySemanticsLabel('Reset crop'), findsOneWidget);

    await pumpTheme(AppTheme.darkTheme);
    expect(find.byKey(ProfilePhotoCropScreen.titleKey), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
  });

  testWidgets('cancel pops without a cropped file', (tester) async {
    File? result;
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await ProfilePhotoCropScreen.open(
                      context,
                      File('missing-profile-crop.png'),
                    );
                  },
                  child: const Text('open-crop'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-crop'));
    await tester.pump();

    expect(find.byKey(ProfilePhotoCropScreen.titleKey), findsOneWidget);
    await tester.tap(find.byKey(ProfilePhotoCropScreen.cancelKey));
    await tester.pump();

    expect(find.byKey(ProfilePhotoCropScreen.titleKey), findsNothing);
    expect(result, isNull);
  });
}
