import 'package:flutter/widgets.dart';

/// What presence should do for an [AppLifecycleState].
enum PresenceLifecycleSignal { online, offline, none }

/// Home / lock screen use [AppLifecycleState.paused]. Android 14 also reports
/// [AppLifecycleState.hidden] when the app leaves the foreground.
/// [AppLifecycleState.inactive] is only a transition (app switcher, permission
/// dialog animation) and must not flip presence.
PresenceLifecycleSignal presenceSignalForLifecycle(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      return PresenceLifecycleSignal.online;
    case AppLifecycleState.paused:
    case AppLifecycleState.detached:
    case AppLifecycleState.hidden:
      return PresenceLifecycleSignal.offline;
    case AppLifecycleState.inactive:
      return PresenceLifecycleSignal.none;
  }
}
