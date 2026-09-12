import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/routes/app_router.dart';

import '../e2e/helpers/mock_services.dart';

class _CountingTokenStorage extends InMemoryTokenStorage {
  int profileTokenReads = 0;

  @override
  Future<String?> getProfileCompletionToken() async {
    profileTokenReads++;
    return super.getProfileCompletionToken();
  }
}

void main() {
  setUp(resetAuthStageCache);

  group('resolveAuthStage', () {
    test('treats a surviving auth token with no session as authenticated',
        () async {
      final storage = InMemoryTokenStorage()..seedAuthTokenWithoutSession();

      expect(await resolveAuthStage(storage), AuthStage.authenticated);
    });

    test('does not send completed users to the wizard for a leftover token',
        () async {
      final storage = InMemoryTokenStorage()
        ..seedCompletedProfile(leftoverProfileToken: true);

      expect(await resolveAuthStage(storage), AuthStage.authenticated);
    });

    test('does not treat a leftover wizard token as incomplete after cache wipe',
        () async {
      final storage = InMemoryTokenStorage()
        ..seedAuthTokenWithoutSession(leftoverProfileToken: true);

      expect(await resolveAuthStage(storage), AuthStage.authenticated);
    });

    test('still routes incomplete profiles to the wizard', () async {
      final storage = InMemoryTokenStorage()..seedIncompleteProfile();

      expect(await resolveAuthStage(storage), AuthStage.profileCompletion);
    });

    test('routes wizard-only tokens to profile completion', () async {
      final storage = InMemoryTokenStorage()..seedProfileCompletion();

      expect(await resolveAuthStage(storage), AuthStage.profileCompletion);
    });

    test('routes missing tokens as unauthenticated', () async {
      final storage = InMemoryTokenStorage()..seedUnauthenticated();

      expect(await resolveAuthStage(storage), AuthStage.unauthenticated);
    });
  });

  group('resolveAuthStageCached', () {
    test('reuses the stage until authRevision changes', () async {
      final storage = _CountingTokenStorage()..seedAuthenticated();

      expect(await resolveAuthStageCached(storage), AuthStage.authenticated);
      expect(await resolveAuthStageCached(storage), AuthStage.authenticated);
      expect(storage.profileTokenReads, 1);

      storage.seedUnauthenticated();
      expect(await resolveAuthStageCached(storage), AuthStage.unauthenticated);
      expect(storage.profileTokenReads, 2);
    });
  });
}
