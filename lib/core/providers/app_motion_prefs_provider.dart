import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feature_flags_provider.dart';

/// Persisted Reduce Motion / haptic gates (PERF-SCR-A11Y-001 / HAPTIC-001).
///
/// OS `MediaQuery.disableAnimations` still wins. This flag is an in-app override
/// so stagger/Lottie/shimmer short-circuit without a unused settings stub.
class AppMotionPreferences {
  AppMotionPreferences._();

  static const reduceMotionKey = 'app_reduce_motion';
  static const hapticsEnabledKey = 'app_haptics_enabled';
  static const solidNavBarKey = 'app_solid_nav_bar';

  static bool reduceMotion = false;
  static bool hapticsEnabled = true;
  static bool solidNavBar = false;

  static void hydrate(SharedPreferences? prefs) {
    reduceMotion = prefs?.getBool(reduceMotionKey) ?? false;
    hapticsEnabled = prefs?.getBool(hapticsEnabledKey) ?? true;
    solidNavBar = prefs?.getBool(solidNavBarKey) ?? false;
  }
}

class AppMotionPrefsState {
  const AppMotionPrefsState({
    this.reduceMotion = false,
    this.hapticsEnabled = true,
    this.solidNavBar = false,
  });

  final bool reduceMotion;
  final bool hapticsEnabled;
  final bool solidNavBar;

  AppMotionPrefsState copyWith({
    bool? reduceMotion,
    bool? hapticsEnabled,
    bool? solidNavBar,
  }) {
    return AppMotionPrefsState(
      reduceMotion: reduceMotion ?? this.reduceMotion,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      solidNavBar: solidNavBar ?? this.solidNavBar,
    );
  }
}

final appMotionPrefsProvider =
    NotifierProvider<AppMotionPrefsNotifier, AppMotionPrefsState>(
      AppMotionPrefsNotifier.new,
    );

class AppMotionPrefsNotifier extends Notifier<AppMotionPrefsState> {
  @override
  AppMotionPrefsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    AppMotionPreferences.hydrate(prefs);
    return AppMotionPrefsState(
      reduceMotion: AppMotionPreferences.reduceMotion,
      hapticsEnabled: AppMotionPreferences.hapticsEnabled,
      solidNavBar: AppMotionPreferences.solidNavBar,
    );
  }

  Future<void> setReduceMotion(bool value) async {
    AppMotionPreferences.reduceMotion = value;
    state = state.copyWith(reduceMotion: value);
    await ref
        .read(sharedPreferencesProvider)
        ?.setBool(AppMotionPreferences.reduceMotionKey, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    AppMotionPreferences.hapticsEnabled = value;
    state = state.copyWith(hapticsEnabled: value);
    await ref
        .read(sharedPreferencesProvider)
        ?.setBool(AppMotionPreferences.hapticsEnabledKey, value);
  }

  Future<void> setSolidNavBar(bool value) async {
    AppMotionPreferences.solidNavBar = value;
    state = state.copyWith(solidNavBar: value);
    await ref
        .read(sharedPreferencesProvider)
        ?.setBool(AppMotionPreferences.solidNavBarKey, value);
  }
}
