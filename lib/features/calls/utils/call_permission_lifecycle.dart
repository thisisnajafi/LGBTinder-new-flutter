import 'package:flutter/widgets.dart';

/// The OS mic/camera prompt pauses the Flutter activity.
///
/// That pause is not the user leaving the app, declining, or cancelling.
/// Home and the lock screen still use [AppLifecycleState.paused] and must
/// keep promoting an incoming banner to CallKit.
class CallPermissionLifecycle {
  CallPermissionLifecycle._();

  static int _depth = 0;
  static int _ticket = 0;

  /// Stays true for one frame after the dialog closes so a decline or
  /// cancel delivered with the resume is still ignored.
  static bool _suppressTrailing = false;

  /// True while `permission.request()` is waiting on the system dialog.
  static bool get requestInFlight => _depth > 0;

  /// Dialog is up, or it just closed and the resume events are still in flight.
  static bool get blocksCallTerminalActions => _depth > 0 || _suppressTrailing;

  static void beginRequest() {
    _depth += 1;
    _ticket += 1;
    _suppressTrailing = true;
  }

  static void endRequest() {
    if (_depth > 0) _depth -= 1;
    if (_depth > 0) return;
    final ticket = _ticket;
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_depth == 0 && ticket == _ticket) _suppressTrailing = false;
      });
    } catch (_) {
      if (ticket == _ticket) _suppressTrailing = false;
    }
  }

  @visibleForTesting
  static void debugReset() {
    _depth = 0;
    _ticket = 0;
    _suppressTrailing = false;
  }

  /// States Android and iOS emit while a runtime permission dialog is up.
  static bool isPermissionDialogLifecycle(AppLifecycleState state) {
    return state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
  }

  /// Foreground incoming stays on the in-app banner during the prompt.
  /// Showing CallKit here makes the plugin broadcast decline.
  static bool shouldPromoteIncomingToCallKit({
    required AppLifecycleState state,
    required bool permissionRequestInFlight,
  }) {
    if (state == AppLifecycleState.resumed) return false;
    if (permissionRequestInFlight && isPermissionDialogLifecycle(state)) {
      return false;
    }
    return true;
  }

  /// A CallKit decline that arrives while the prompt is up is the dialog.
  static bool shouldPostDecline({required bool permissionRequestInFlight}) {
    return !permissionRequestInFlight;
  }

  /// Do not POST `/calls/end` for a pause caused by the prompt.
  static bool shouldCancelOutgoing({required bool permissionRequestInFlight}) {
    return !permissionRequestInFlight;
  }
}
