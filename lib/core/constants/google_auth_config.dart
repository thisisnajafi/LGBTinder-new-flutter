/// Google Sign-In configuration.
///
/// The web client ID is public (also in `android/app/google-services.json`).
/// Override at build time when needed:
/// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=...`
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String _defaultWebClientId =
      '904491806534-vdhds1qkgv3ijf857d67mtg41hg0elvd.apps.googleusercontent.com';

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: _defaultWebClientId,
  );

  static bool get isConfigured => webClientId.isNotEmpty;
}
