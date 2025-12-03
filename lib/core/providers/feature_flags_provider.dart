import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags for controlling app features and payment systems
class FeatureFlags {
  static const String googlePlayBilling = 'google_play_billing';
  static const String stripePayments = 'stripe_payments';
  static const String offlineMode = 'offline_mode';
  static const String purchaseRestoration = 'purchase_restoration';

  // Default values (Google Play Billing enabled by default for Android)
  static const Map<String, bool> _defaults = {
    googlePlayBilling: true, // Enable Google Play Billing by default
    stripePayments: false,   // Disable Stripe by default (will be used as fallback)
    offlineMode: true,       // Enable offline mode
    purchaseRestoration: true, // Enable purchase restoration
  };

  final SharedPreferences _prefs;

  const FeatureFlags(this._prefs);

  /// Get feature flag value
  bool getFeatureFlag(String key) {
    return _prefs.getBool(key) ?? _defaults[key] ?? false;
  }

  /// Set feature flag value
  Future<void> setFeatureFlag(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  /// Get all feature flags
  Map<String, bool> getAllFeatureFlags() {
    return Map.fromEntries(
      _defaults.keys.map((key) => MapEntry(key, getFeatureFlag(key))),
    );
  }

  // Convenience getters
  bool get isGooglePlayBillingEnabled => getFeatureFlag(googlePlayBilling);
  bool get isStripePaymentsEnabled => getFeatureFlag(stripePayments);
  bool get isOfflineModeEnabled => getFeatureFlag(offlineMode);
  bool get isPurchaseRestorationEnabled => getFeatureFlag(purchaseRestoration);

  /// Get the active payment system
  PaymentSystem get activePaymentSystem {
    if (isGooglePlayBillingEnabled) {
      return PaymentSystem.googlePlay;
    } else if (isStripePaymentsEnabled) {
      return PaymentSystem.stripe;
    } else {
      return PaymentSystem.none;
    }
  }
}

/// Payment system enum
enum PaymentSystem {
  googlePlay,
  stripe,
  none;

  String get displayName {
    switch (this) {
      case PaymentSystem.googlePlay:
        return 'Google Play Billing';
      case PaymentSystem.stripe:
        return 'Stripe';
      case PaymentSystem.none:
        return 'None';
    }
  }

  bool get isAvailable {
    switch (this) {
      case PaymentSystem.googlePlay:
        return true; // Always available on Android
      case PaymentSystem.stripe:
        return true; // Web-based fallback
      case PaymentSystem.none:
        return false;
    }
  }
}

// Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided');
});

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FeatureFlags(prefs);
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

final stripePaymentsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagNotifierProvider)[FeatureFlags.stripePayments] ?? false;
});

final offlineModeEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagNotifierProvider)[FeatureFlags.offlineMode] ?? true;
});

final purchaseRestorationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagNotifierProvider)[FeatureFlags.purchaseRestoration] ?? true;
});

final activePaymentSystemProvider = Provider<PaymentSystem>((ref) {
  final googlePlayEnabled = ref.watch(googlePlayBillingEnabledProvider);
  final stripeEnabled = ref.watch(stripePaymentsEnabledProvider);

  if (googlePlayEnabled) {
    return PaymentSystem.googlePlay;
  } else if (stripeEnabled) {
    return PaymentSystem.stripe;
  } else {
    return PaymentSystem.none;
  }
});
