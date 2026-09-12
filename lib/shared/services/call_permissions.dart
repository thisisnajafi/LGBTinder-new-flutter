import 'package:permission_handler/permission_handler.dart';

/// Result of a mic / camera pre-check for calls.
enum CallPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

/// Thrown when Agora initialize runs without granted media permissions.
class CallPermissionDeniedException implements Exception {
  final CallPermissionResult result;
  final bool video;

  const CallPermissionDeniedException(this.result, {required this.video});

  bool get permanentlyDenied =>
      result == CallPermissionResult.permanentlyDenied;

  @override
  String toString() =>
      'CallPermissionDeniedException(result=$result, video=$video)';
}

/// Copy for the call-permission explanation sheet.
class CallPermissionCopy {
  CallPermissionCopy._();

  static String title({
    required bool video,
    required bool permanentlyDenied,
  }) {
    if (permanentlyDenied) {
      return video
          ? 'Enable camera and microphone'
          : 'Enable microphone';
    }
    return video
        ? 'Camera and microphone needed'
        : 'Microphone needed';
  }

  static String body({
    required bool video,
    required bool permanentlyDenied,
  }) {
    if (permanentlyDenied) {
      return video
          ? 'Access is turned off. Open Settings to allow the camera and microphone, then try the call again.'
          : 'Access is turned off. Open Settings to allow the microphone, then try the call again.';
    }
    return video
        ? 'Video calls need the camera and microphone. Grant access to connect.'
        : 'Voice calls need the microphone. Grant access to connect.';
  }
}

/// Mic (and camera for video) must be granted before initiate / accept.
class CallPermissions {
  CallPermissions._();

  static CallPermissionResult interpret(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return CallPermissionResult.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CallPermissionResult.permanentlyDenied;
    }
    return CallPermissionResult.denied;
  }

  /// Request only when the OS will still show a prompt.
  static Future<CallPermissionResult> ensure({required bool video}) async {
    final mic = await _ensureOne(Permission.microphone);
    if (mic != CallPermissionResult.granted) return mic;
    if (!video) return CallPermissionResult.granted;
    return _ensureOne(Permission.camera);
  }

  static Future<CallPermissionResult> _ensureOne(Permission permission) async {
    final current = interpret(await permission.status);
    if (current == CallPermissionResult.granted) {
      return CallPermissionResult.granted;
    }
    if (current == CallPermissionResult.permanentlyDenied) {
      return CallPermissionResult.permanentlyDenied;
    }
    return interpret(await permission.request());
  }
}
