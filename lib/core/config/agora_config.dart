import 'app_config.dart';

/// Agora RTC configuration.
///
/// Join always prefers `app_id` from the token endpoint. A flavor may set
/// [AppConfig.agoraAppIdOverride]. `--dart-define=AGORA_APP_ID=...` still wins
/// as a last-resort local override. There is no bundled production App ID.
class AgoraConfig {
  AgoraConfig._();

  static String get appId {
    const fromDefine = String.fromEnvironment('AGORA_APP_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (AppConfig.isReady) return AppConfig.current.agoraAppIdOverride;
    return '';
  }

  static bool get isConfigured => appId.isNotEmpty;

  /// Token payload first, then dart-define. Empty if neither is set.
  static String resolveAppId(String? fromToken) {
    final fromEndpoint = fromToken?.trim() ?? '';
    if (fromEndpoint.isNotEmpty) return fromEndpoint;
    return appId.trim();
  }

  static bool hasAppId(String? fromToken) => resolveAppId(fromToken).isNotEmpty;
}
