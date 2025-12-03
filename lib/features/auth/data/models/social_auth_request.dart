/// Social authentication request model
/// Used for OAuth callbacks from social providers
class SocialAuthRequest {
  final String code;
  final String state;
  final String provider;

  SocialAuthRequest({
    required this.code,
    required this.state,
    this.provider = 'google',
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'state': state,
      'provider': provider,
    };
  }
}
