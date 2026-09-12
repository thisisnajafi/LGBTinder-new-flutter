import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:lgbtindernew/features/chat/utils/chat_media_permissions.dart';

void main() {
  group('ChatMediaPermissions.interpret', () {
    test('granted-like statuses allow sending', () {
      expect(
        ChatMediaPermissions.interpret(PermissionStatus.granted),
        ChatMediaPermissionResult.granted,
      );
      expect(
        ChatMediaPermissions.interpret(PermissionStatus.limited),
        ChatMediaPermissionResult.granted,
      );
      expect(
        ChatMediaPermissions.interpret(PermissionStatus.provisional),
        ChatMediaPermissionResult.granted,
      );
    });

    test('permanent / restricted skip the OS prompt', () {
      expect(
        ChatMediaPermissions.interpret(PermissionStatus.permanentlyDenied),
        ChatMediaPermissionResult.permanentlyDenied,
      );
      expect(
        ChatMediaPermissions.interpret(PermissionStatus.restricted),
        ChatMediaPermissionResult.permanentlyDenied,
      );
    });

    test('denied is not treated as granted', () {
      expect(
        ChatMediaPermissions.interpret(PermissionStatus.denied),
        ChatMediaPermissionResult.denied,
      );
    });
  });

  group('ChatMediaPermissions.permissionFor', () {
    test('camera and mic map to the matching OS permission', () {
      expect(
        ChatMediaPermissions.permissionFor(ChatMediaPermissionKind.camera),
        Permission.camera,
      );
      expect(
        ChatMediaPermissions.permissionFor(ChatMediaPermissionKind.microphone),
        Permission.microphone,
      );
    });

    test('Android 12 gallery uses storage; 13+ uses photos/videos', () {
      expect(
        ChatMediaPermissions.permissionFor(
          ChatMediaPermissionKind.photos,
          isAndroid: true,
          androidSdk: 32,
        ),
        Permission.storage,
      );
      expect(
        ChatMediaPermissions.permissionFor(
          ChatMediaPermissionKind.photos,
          isAndroid: true,
          androidSdk: 33,
        ),
        Permission.photos,
      );
      expect(
        ChatMediaPermissions.permissionFor(
          ChatMediaPermissionKind.videos,
          isAndroid: true,
          androidSdk: 33,
        ),
        Permission.videos,
      );
    });
  });

  group('ChatMediaPermissionCopy', () {
    test('permanently denied tells the user to open Settings', () {
      expect(
        ChatMediaPermissionCopy.title(
          kind: ChatMediaPermissionKind.camera,
          permanentlyDenied: true,
        ),
        'Enable camera',
      );
      expect(
        ChatMediaPermissionCopy.body(
          kind: ChatMediaPermissionKind.photos,
          permanentlyDenied: true,
        ),
        contains('Open Settings'),
      );
      expect(ChatMediaPermissionCopy.openSettingsLabel, 'Open Settings');
    });

    test('first denial explains why access is needed', () {
      expect(
        ChatMediaPermissionCopy.title(
          kind: ChatMediaPermissionKind.microphone,
          permanentlyDenied: false,
        ),
        'Microphone needed',
      );
      expect(
        ChatMediaPermissionCopy.body(
          kind: ChatMediaPermissionKind.camera,
          permanentlyDenied: false,
        ),
        contains('camera'),
      );
    });
  });
}
