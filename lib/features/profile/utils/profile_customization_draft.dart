import 'package:flutter/foundation.dart';

/// Draft for [AdvancedProfileCustomizationScreen] (PERF-SCR-CUSTOM-001).
class ProfileCustomizationDraft extends ChangeNotifier {
  String layout = 'default';
  String colorScheme = 'default';
  bool showBadges = true;
  bool showStats = true;
  bool showInterests = true;
  bool showEducation = true;
  bool showWork = true;
  String bioStyle = 'standard';
  bool enableAnimations = true;
  double opacity = 1;

  void setLayout(String value) {
    if (layout == value) return;
    layout = value;
    notifyListeners();
  }

  void setColorScheme(String value) {
    if (colorScheme == value) return;
    colorScheme = value;
    notifyListeners();
  }

  void setBioStyle(String value) {
    if (bioStyle == value) return;
    bioStyle = value;
    notifyListeners();
  }

  void setShowBadges(bool value) {
    showBadges = value;
    notifyListeners();
  }

  void setShowStats(bool value) {
    showStats = value;
    notifyListeners();
  }

  void setShowInterests(bool value) {
    showInterests = value;
    notifyListeners();
  }

  void setShowEducation(bool value) {
    showEducation = value;
    notifyListeners();
  }

  void setShowWork(bool value) {
    showWork = value;
    notifyListeners();
  }

  void setEnableAnimations(bool value) {
    enableAnimations = value;
    notifyListeners();
  }

  void setOpacity(double value) {
    if (opacity == value) return;
    opacity = value;
    notifyListeners();
  }
}
