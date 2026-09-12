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

  static bool reduceMotion = false;
  static bool hapticsEnabled = true;

  static void hydrate(SharedPreferences? prefs) {
    reduceMotion = prefs?.getBool(reduceMotionKey) ?? false;
    hapticsEnabled = prefs?.getBool(hapticsEnabledKey) ?? true;
  }
}

class AppMotionPrefsState {
  const AppMotionPrefsState({
    this.reduceMotion = false,
    this.hapticsEnabled = true,
  });

  final bool reduceMotion;
  final bool hapticsEnabled;

  AppMotionPrefsState copyWith({
    bool? reduceMotion,
    bool? hapticsEnabled,
  }) {
    return AppMotionPrefsState(
      reduceMotion: reduceMotion ?? this.reduceMotion,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
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
}
