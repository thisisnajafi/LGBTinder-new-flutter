import '../config/app_config.dart';

/// Google Sign-In configuration.
///
/// The web client ID is public (also in the production `google-services.json`).
/// The installed flavor supplies it. A missing flavor falls back to the
/// production client id so existing tests keep working.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static String get webClientId {
    if (AppConfig.isReady && AppConfig.current.googleWebClientId.isNotEmpty) {
      return AppConfig.current.googleWebClientId;
    }
    return AppConfig.defaultGoogleWebClientId;
  }

  static bool get isConfigured => webClientId.isNotEmpty;
}
