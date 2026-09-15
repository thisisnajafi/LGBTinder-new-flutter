import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/display_refresh.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/agora_call_video_layer.dart';
import 'package:lgbtindernew/shared/services/fcm_background_handler.dart';

void main() {
  test('manifest enables Android predictive back', () {
    final xml = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(xml, contains('android:enableOnBackInvokedCallback="true"'));
  });

  test('displayRefreshRateHz is non-negative with a binding', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(displayRefreshRateHz(), greaterThanOrEqualTo(0));
  });

  test('Agora video uses Flutter texture (SurfaceProducer) path', () {
    expect(kAgoraUseFlutterTexture, isTrue);
  });

  test('FCM background handler is a top-level isolate entry', () {
    expect(firebaseMessagingBackgroundHandler, isA<Function>());
  });

  test('release minify and baseline profile are wired', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('isMinifyEnabled = true'));
    expect(gradle, contains('isShrinkResources = true'));
    expect(gradle, contains('androidx.profileinstaller:profileinstaller'));
    expect(
      File('android/app/src/main/baseline-prof.txt').existsSync(),
      isTrue,
    );
  });

  test('ProGuard keeps Agora, Firebase, and Pusher', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();
    expect(rules, contains('io.agora.'));
    expect(rules, contains('com.google.firebase.'));
    expect(rules, contains('com.pusher.'));
  });
}
