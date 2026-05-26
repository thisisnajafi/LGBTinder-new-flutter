/// Agora RTC configuration.
///
/// Override at build time:
/// `flutter run --dart-define=AGORA_APP_ID=your_app_id`
class AgoraConfig {
  AgoraConfig._();

  static const String appId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '66ec2577665249188fd54334b11f3cd4',
  );

  static bool get isConfigured => appId.isNotEmpty;
}
