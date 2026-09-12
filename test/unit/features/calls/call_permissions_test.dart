import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:lgbtindernew/shared/services/call_permissions.dart';

void main() {
  group('CallPermissions.interpret', () {
    test('granted-like statuses allow a call', () {
      expect(
        CallPermissions.interpret(PermissionStatus.granted),
        CallPermissionResult.granted,
      );
      expect(
        CallPermissions.interpret(PermissionStatus.limited),
        CallPermissionResult.granted,
      );
      expect(
        CallPermissions.interpret(PermissionStatus.provisional),
        CallPermissionResult.granted,
      );
    });

    test('permanent / restricted skip the OS prompt', () {
      expect(
        CallPermissions.interpret(PermissionStatus.permanentlyDenied),
        CallPermissionResult.permanentlyDenied,
      );
      expect(
        CallPermissions.interpret(PermissionStatus.restricted),
        CallPermissionResult.permanentlyDenied,
      );
    });

    test('denied is not treated as granted', () {
      expect(
        CallPermissions.interpret(PermissionStatus.denied),
        CallPermissionResult.denied,
      );
    });
  });

  group('CallPermissionCopy', () {
    test('permanently denied offers settings-focused copy', () {
      expect(
        CallPermissionCopy.title(video: false, permanentlyDenied: true),
        'Enable microphone',
      );
      expect(
        CallPermissionCopy.body(video: true, permanentlyDenied: true),
        contains('Open Settings'),
      );
    });

    test('first denial explains why access is needed', () {
      expect(
        CallPermissionCopy.title(video: true, permanentlyDenied: false),
        'Camera and microphone needed',
      );
      expect(
        CallPermissionCopy.body(video: false, permanentlyDenied: false),
        contains('microphone'),
      );
    });
  });
}
