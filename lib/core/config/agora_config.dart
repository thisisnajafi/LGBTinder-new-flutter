/// Agora RTC configuration.
///
/// Join always prefers `app_id` from the token endpoint. An optional
/// `--dart-define=AGORA_APP_ID=...` is only a last-resort override for local
/// builds — there is no bundled App ID.
class AgoraConfig {
  AgoraConfig._();

  static const String appId = String.fromEnvironment('AGORA_APP_ID');

  static bool get isConfigured => appId.isNotEmpty;

  /// Token payload first, then dart-define. Empty if neither is set.
  static String resolveAppId(String? fromToken) {
    final fromEndpoint = fromToken?.trim() ?? '';
    if (fromEndpoint.isNotEmpty) return fromEndpoint;
    return appId.trim();
  }

  static bool hasAppId(String? fromToken) => resolveAppId(fromToken).isNotEmpty;
}
