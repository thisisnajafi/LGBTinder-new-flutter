import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/providers/app_motion_prefs_provider.dart';
import 'package:lgbtindernew/core/utils/app_haptics.dart';
import 'package:lgbtindernew/features/calls/utils/call_settings_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    AppMotionPreferences.reduceMotion = false;
    AppMotionPreferences.hapticsEnabled = true;
  });

  testWidgets('in-app reduce motion disables AppAnimations', (tester) async {
    AppMotionPreferences.reduceMotion = true;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            expect(AppAnimations.animationsEnabled(context), isFalse);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('OS reduce motion disables AppAnimations', (tester) async {
    AppMotionPreferences.reduceMotion = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            expect(AppAnimations.animationsEnabled(context), isFalse);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  test('haptics gate follows AppMotionPreferences', () {
    AppMotionPreferences.hapticsEnabled = false;
    expect(AppHaptics.enabled, isFalse);
    AppMotionPreferences.hapticsEnabled = true;
    expect(AppHaptics.enabled, isTrue);
  });

  test('hydrate reads SharedPreferences flags', () async {
    SharedPreferences.setMockInitialValues({
      AppMotionPreferences.reduceMotionKey: true,
      AppMotionPreferences.hapticsEnabledKey: false,
    });
    final prefs = await SharedPreferences.getInstance();
    AppMotionPreferences.hydrate(prefs);
    expect(AppMotionPreferences.reduceMotion, isTrue);
    expect(AppMotionPreferences.hapticsEnabled, isFalse);
  });

  test('call settings draft notifies on toggle not duplicate busy', () {
    final draft = CallSettingsDraft();
    var count = 0;
    draft.addListener(() => count++);
    draft.setVideoEnabled(false);
    draft.setVideoEnabled(false);
    draft.setBusy(true);
    draft.setBusy(true);
    expect(draft.videoEnabled, isFalse);
    expect(count, 2);
    draft.dispose();
  });
}
