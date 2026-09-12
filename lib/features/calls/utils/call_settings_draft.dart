import 'package:flutter/foundation.dart';

/// Local draft for [CallSettingsScreen] so toggles do not rebuild the scaffold
/// (PERF-SCR-CALLSET-001).
class CallSettingsDraft extends ChangeNotifier {
  bool videoEnabled = true;
  bool audioEnabled = true;
  bool callWaiting = true;
  bool autoAcceptCalls = false;
  bool isBusy = false;

  void hydrate({
    required bool videoEnabled,
    required bool audioEnabled,
    required bool callWaiting,
    required bool autoAcceptCalls,
  }) {
    this.videoEnabled = videoEnabled;
    this.audioEnabled = audioEnabled;
    this.callWaiting = callWaiting;
    this.autoAcceptCalls = autoAcceptCalls;
    notifyListeners();
  }

  void setBusy(bool value) {
    if (isBusy == value) return;
    isBusy = value;
    notifyListeners();
  }

  void setVideoEnabled(bool value) {
    if (videoEnabled == value) return;
    videoEnabled = value;
    notifyListeners();
  }

  void setAudioEnabled(bool value) {
    if (audioEnabled == value) return;
    audioEnabled = value;
    notifyListeners();
  }

  void setCallWaiting(bool value) {
    if (callWaiting == value) return;
    callWaiting = value;
    notifyListeners();
  }

  void setAutoAcceptCalls(bool value) {
    if (autoAcceptCalls == value) return;
    autoAcceptCalls = value;
    notifyListeners();
  }
}
