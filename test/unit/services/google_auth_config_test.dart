import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/constants/google_auth_config.dart';

void main() {
  group('GoogleAuthConfig', () {
    test('uses the production web client ID by default', () {
      expect(
        GoogleAuthConfig.webClientId,
        '904491806534-vdhds1qkgv3ijf857d67mtg41hg0elvd.apps.googleusercontent.com',
      );
      expect(GoogleAuthConfig.isConfigured, isTrue);
    });
  });
}
