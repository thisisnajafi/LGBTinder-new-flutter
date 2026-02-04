import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags for controlling app features and payment systems
class FeatureFlags {
  static const String googlePlayBilling = 'google_play_billing';
  static const String offlineMode = 'offline_mode';
  static const String purchaseRestoration = 'purchase_restoration';

  // Default values (Google Play Billing enabled by default for Android)
  static const Map<String, bool> _defaults = {
    googlePlayBilling: true, // Enable Google Play Billing by default
    offlineMode: true,       // Enable offline mode
    purchaseRestoration: true, // Enable purchase restoration
  };

  final SharedPreferences? _prefs;

  const FeatureFlags(this._prefs);

  /// Get feature flag value
  bool getFeatureFlag(String key) {
    if (_prefs == null) {
      return _defaults[key] ?? false;
    }
    return _prefs!.getBool(key) ?? _defaults[key] ?? false;
  }

  /// Set feature flag value
  Future<void> setFeatureFlag(String key, bool value) async {
    if (_prefs == null) {
      // Silently fail if SharedPreferences is not available
      return;
    }
    await _prefs!.setBool(key, value);
  }

  /// Get all feature flags
  Map<String, bool> getAllFeatureFlags() {
    return Map.fromEntries(
      _defaults.keys.map((key) => MapEntry(key, getFeatureFlag(key))),
    );
  }

  // Convenience getters
  bool get isGooglePlayBillingEnabled => getFeatureFlag(googlePlayBilling);
  bool get isOfflineModeEnabled => getFeatureFlag(offlineMode);
  bool get isPurchaseRestorationEnabled => getFeatureFlag(purchaseRestoration);

  /// Get the active payment system (Google Play only; Stripe removed)
  PaymentSystem get activePaymentSystem {
    return isGooglePlayBillingEnabled ? PaymentSystem.googlePlay : PaymentSystem.none;
  }
}

/// Payment system enum (Stripe removed; Google Play only)
enum PaymentSystem {
  googlePlay,
  none;

  String get displayName {
    switch (this) {
      case PaymentSystem.googlePlay:
        return 'Google Play Billing';
      case PaymentSystem.none:
        return 'None';
    }
  }

  bool get isAvailable {
    switch (this) {
      case PaymentSystem.googlePlay:
        return true; // Always available on Android
      case PaymentSystem.none:
        return false;
    }
  }
}

// Providers
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return null; // Will be overridden in main.dart if available
});

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FeatureFlags(prefs); // FeatureFlags should handle null prefs
});

// Feature flag state notifiers for reactive updates
class FeatureFlagNotifier extends StateNotifier<Map<String, bool>> {
  final FeatureFlags _featureFlags;

  FeatureFlagNotifier(this._featureFlags) : super(_featureFlags.getAllFeatureFlags());

  Future<void> setFeatureFlag(String key, bool value) async {
    await _featureFlags.setFeatureFlag(key, value);
    state = {...state, key: value};
  }

  Future<void> toggleFeatureFlag(String key) async {
    final currentValue = state[key] ?? false;
    await setFeatureFlag(key, !currentValue);
  }

  bool getFeatureFlag(String key) => state[key] ?? false;
}

final featureFlagNotifierProvider = StateNotifierProvider<FeatureFlagNotifier, Map<String, bool>>((ref) {
  final featureFlags = ref.watch(featureFlagsProvider);
  return FeatureFlagNotifier(featureFlags);
});

// Convenience providers for specific features
final googlePlayBillingEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagNotifierProvider)[FeatureFlags.googlePlayBilling] ?? false;
});

final offlineModeEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagNotifierProvider)[FeatureFlags.offlineMode] ?? true;
});

final purchaseRestorationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagNotifierProvider)[FeatureFlags.purchaseRestoration] ?? true;
});

final activePaymentSystemProvider = Provider<PaymentSystem>((ref) {
  final googlePlayEnabled = ref.watch(googlePlayBillingEnabledProvider);
  return googlePlayEnabled ? PaymentSystem.googlePlay : PaymentSystem.none;
});
