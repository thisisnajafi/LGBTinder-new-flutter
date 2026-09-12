import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera, library, or mic access for sending chat media (CHAT-IMG-005).
enum ChatMediaPermissionKind { camera, photos, videos, microphone }

enum ChatMediaPermissionResult { granted, denied, permanentlyDenied }

/// Copy for the chat-media permission sheet.
class ChatMediaPermissionCopy {
  ChatMediaPermissionCopy._();

  static String title({
    required ChatMediaPermissionKind kind,
    required bool permanentlyDenied,
  }) {
    if (permanentlyDenied) {
      switch (kind) {
        case ChatMediaPermissionKind.camera:
          return 'Enable camera';
        case ChatMediaPermissionKind.microphone:
          return 'Enable microphone';
        case ChatMediaPermissionKind.photos:
        case ChatMediaPermissionKind.videos:
          return 'Enable photos';
      }
    }
    switch (kind) {
      case ChatMediaPermissionKind.camera:
        return 'Camera needed';
      case ChatMediaPermissionKind.microphone:
        return 'Microphone needed';
      case ChatMediaPermissionKind.photos:
      case ChatMediaPermissionKind.videos:
        return 'Photo access needed';
    }
  }

  static String body({
    required ChatMediaPermissionKind kind,
    required bool permanentlyDenied,
  }) {
    if (permanentlyDenied) {
      switch (kind) {
        case ChatMediaPermissionKind.camera:
          return 'Access is turned off. Open Settings to allow the camera, then try again.';
        case ChatMediaPermissionKind.microphone:
          return 'Access is turned off. Open Settings to allow the microphone, then try again.';
        case ChatMediaPermissionKind.photos:
        case ChatMediaPermissionKind.videos:
          return 'Access is turned off. Open Settings to allow photos, then try again.';
      }
    }
    switch (kind) {
      case ChatMediaPermissionKind.camera:
        return 'Taking a photo needs the camera. Grant access to continue.';
      case ChatMediaPermissionKind.microphone:
        return 'Voice messages need the microphone. Grant access to continue.';
      case ChatMediaPermissionKind.photos:
      case ChatMediaPermissionKind.videos:
        return 'Choosing a photo needs library access. Grant access to continue.';
    }
  }

  static const openSettingsLabel = 'Open Settings';
}

/// Pre-check photos / camera / mic before ImagePicker or the voice recorder.
class ChatMediaPermissions {
  ChatMediaPermissions._();

  static ChatMediaPermissionResult interpret(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return ChatMediaPermissionResult.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return ChatMediaPermissionResult.permanentlyDenied;
    }
    return ChatMediaPermissionResult.denied;
  }

  static Permission permissionFor(
    ChatMediaPermissionKind kind, {
    bool isAndroid = false,
    int androidSdk = 33,
  }) {
    switch (kind) {
      case ChatMediaPermissionKind.camera:
        return Permission.camera;
      case ChatMediaPermissionKind.microphone:
        return Permission.microphone;
      case ChatMediaPermissionKind.photos:
        if (isAndroid && androidSdk < 33) return Permission.storage;
        return Permission.photos;
      case ChatMediaPermissionKind.videos:
        if (!isAndroid) return Permission.photos;
        if (androidSdk < 33) return Permission.storage;
        return Permission.videos;
    }
  }

  static Future<ChatMediaPermissionResult> ensure(
    ChatMediaPermissionKind kind,
  ) async {
    final sdk = Platform.isAndroid
        ? (await DeviceInfoPlugin().androidInfo).version.sdkInt
        : 33;
    final permission = permissionFor(
      kind,
      isAndroid: Platform.isAndroid,
      androidSdk: sdk,
    );
    final current = interpret(await permission.status);
    if (current == ChatMediaPermissionResult.granted) {
      return ChatMediaPermissionResult.granted;
    }
    if (current == ChatMediaPermissionResult.permanentlyDenied) {
      return ChatMediaPermissionResult.permanentlyDenied;
    }
    return interpret(await permission.request());
  }
}
