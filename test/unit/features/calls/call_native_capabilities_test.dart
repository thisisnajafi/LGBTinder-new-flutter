import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String root;

  setUpAll(() {
    root = Directory.current.path;
    if (!File('$root/ios/Runner/Info.plist').existsSync()) {
      fail('Expected to run from the Flutter package root (lgbtindernew).');
    }
  });

  test('Info.plist declares voip and audio background modes', () {
    final plist = File('$root/ios/Runner/Info.plist').readAsStringSync();
    expect(plist.contains('<key>UIBackgroundModes</key>'), isTrue);
    expect(plist.contains('<string>voip</string>'), isTrue);
    expect(plist.contains('<string>audio</string>'), isTrue);
    expect(plist.contains('<string>remote-notification</string>'), isTrue);
  });

  test('Android manifest declares phone-call FGS and MANAGE_OWN_CALLS', () {
    final manifest = File(
      '$root/android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest.contains('android.permission.POST_NOTIFICATIONS'),
      isTrue,
    );
    expect(
      manifest.contains('android.permission.USE_FULL_SCREEN_INTENT'),
      isTrue,
    );
    expect(
      manifest.contains('android.permission.FOREGROUND_SERVICE_PHONE_CALL'),
      isTrue,
    );
    expect(
      manifest.contains('android.permission.FOREGROUND_SERVICE_MICROPHONE'),
      isTrue,
    );
    expect(
      manifest.contains('android.permission.MANAGE_OWN_CALLS'),
      isTrue,
    );
    expect(
      manifest.contains('android.permission.SYSTEM_ALERT_WINDOW'),
      isTrue,
    );
    expect(
      manifest.contains('android.permission.BLUETOOTH_CONNECT'),
      isTrue,
    );
  });

  test('CallKitLogo imageset exists for iconName CallKitLogo', () {
    final contents = File(
      '$root/ios/Runner/Assets.xcassets/CallKitLogo.imageset/Contents.json',
    );
    expect(contents.existsSync(), isTrue);
    expect(contents.readAsStringSync(), contains('CallKitLogo.png'));
    expect(
      File(
        '$root/ios/Runner/Assets.xcassets/CallKitLogo.imageset/CallKitLogo.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$root/ios/Runner/Assets.xcassets/CallKitLogo.imageset/CallKitLogo@2x.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$root/ios/Runner/Assets.xcassets/CallKitLogo.imageset/CallKitLogo@3x.png',
      ).existsSync(),
      isTrue,
    );
  });
}
