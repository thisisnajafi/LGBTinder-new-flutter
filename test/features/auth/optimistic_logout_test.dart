import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:lgbtindernew/features/auth/data/models/login_response.dart';
import 'package:lgbtindernew/features/auth/data/services/auth_service.dart';
import 'package:lgbtindernew/features/auth/providers/auth_provider.dart';
import 'package:lgbtindernew/shared/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../e2e/helpers/mock_services.dart';

class _FakeAuthService extends Fake implements AuthService {
  _FakeAuthService({
    this.logoutCompleter,
    this.logoutError,
    this.logoutDelay = Duration.zero,
  });

  /// When non-null, [logout] waits on this (never completes unless completed).
  final Completer<void>? logoutCompleter;
  final Object? logoutError;
  final Duration logoutDelay;

  int logoutCalls = 0;
  int clearHeaderCalls = 0;
  String? lastBearerToken;
  String? lastDeviceToken;

  @override
  void clearInMemoryAuthHeader() {
    clearHeaderCalls++;
  }

  @override
  Future<void> logout({String? bearerToken, String? deviceToken}) async {
    logoutCalls++;
    lastBearerToken = bearerToken;
    lastDeviceToken = deviceToken;
    if (logoutError != null) {
      throw logoutError!;
    }
    if (logoutDelay > Duration.zero) {
      await Future<void>.delayed(logoutDelay);
    }
    if (logoutCompleter != null) {
      await logoutCompleter!.future;
    }
  }
}

class _RecordingOnboarding extends OnboardingService {
  @override
  Future<bool> isOnboardingCompleted() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('redactSensitiveBody', () {
    test('redacts password and tokens in API request bodies', () {
      final redacted = redactSensitiveBody({
        'email': 'a@b.com',
        'password': 'secret',
        'password_confirmation': 'secret',
        'token': 'tok',
        'refresh_token': 'r',
        'nested': {'access_token': 'x', 'ok': 1},
      });

      expect(redacted!['email'], 'a@b.com');
      expect(redacted['password'], '***');
      expect(redacted['password_confirmation'], '***');
      expect(redacted['token'], '***');
      expect(redacted['refresh_token'], '***');
      expect((redacted['nested'] as Map)['access_token'], '***');
      expect((redacted['nested'] as Map)['ok'], 1);
    });
  });

  group('AuthProviderNotifier optimistic logout', () {
    late InMemoryTokenStorage storage;
    late _FakeAuthService auth;
    late List<String> events;
    late AuthProviderNotifier notifier;

    AuthProviderNotifier buildNotifier({
      Completer<void>? logoutCompleter,
      Object? logoutError,
      Duration logoutDelay = Duration.zero,
      Future<void> Function()? onPurge,
    }) {
      storage = InMemoryTokenStorage()
        ..seedCompletedProfile(token: 'old-session-token');
      auth = _FakeAuthService(
        logoutCompleter: logoutCompleter,
        logoutError: logoutError,
        logoutDelay: logoutDelay,
      );
      events = <String>[];
      return AuthProviderNotifier(
        auth,
        storage,
        _RecordingOnboarding(),
        () async {
          events.add('purge');
          if (onPurge != null) await onPurge();
        },
        () => events.add('in_memory_reset'),
      );
    }

    tearDown(() async {
      final pending = notifier.pendingBackgroundLogout;
      if (pending != null) {
        try {
          await pending.timeout(const Duration(milliseconds: 50));
        } catch (_) {}
      }
      notifier.dispose();
    });

    test('clears local state without awaiting network logout', () async {
      final hang = Completer<void>();
      notifier = buildNotifier(logoutCompleter: hang);

      // Finish checkAuthStatus microtask.
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isAuthenticated, isTrue);

      final logoutFuture = notifier.logout();
      // Local clear must finish even while remote hang is open.
      await logoutFuture;

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(await storage.isAuthenticated(), isFalse);
      expect(events, contains('in_memory_reset'));
      expect(hang.isCompleted, isFalse);
      // Remote may already have been scheduled; do not require it finished.
      hang.complete();
      await notifier.pendingBackgroundLogout;
      expect(auth.logoutCalls, 1);
      expect(auth.lastBearerToken, 'old-session-token');
    });

    test('swallows background logout errors', () async {
      notifier = buildNotifier(logoutError: Exception('network down'));
      await Future<void>.delayed(Duration.zero);

      await notifier.logout();
      await notifier.pendingBackgroundLogout;

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.errorMessage, isNull);
      expect(auth.logoutCalls, 1);
    });

    test('late background completion after re-login does not wipe new session',
        () async {
      final hang = Completer<void>();
      var purgeCount = 0;
      notifier = buildNotifier(
        logoutCompleter: hang,
        onPurge: () async {
          purgeCount++;
        },
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.logout();
      expect(await storage.isAuthenticated(), isFalse);

      // Simulate re-login as a different user before background finishes.
      await storage.saveAuthToken('new-session-token');
      await notifier.login(
        LoginResponse(
          token: 'new-session-token',
          profileCompleted: true,
          needsProfileCompletion: false,
          userState: 'ready',
          user: UserData(
            id: 99,
            firstName: 'New',
            lastName: 'User',
            email: 'new@test.com',
          ),
        ),
      );

      expect(notifier.state.isAuthenticated, isTrue);
      expect(await storage.getAuthToken(), 'new-session-token');
      final purgesAfterLogin = purgeCount;

      hang.complete();
      await notifier.pendingBackgroundLogout;

      expect(await storage.getAuthToken(), 'new-session-token');
      expect(notifier.state.isAuthenticated, isTrue);
      // Login already purged once; background must not purge again.
      expect(purgeCount, purgesAfterLogin);
    });

    test('double logout is a no-op', () async {
      final hang = Completer<void>();
      notifier = buildNotifier(logoutCompleter: hang);
      await Future<void>.delayed(Duration.zero);

      await notifier.logout();
      await notifier.logout();
      await notifier.logout();

      hang.complete();
      await notifier.pendingBackgroundLogout;

      expect(auth.logoutCalls, 1);
      expect(notifier.state.isAuthenticated, isFalse);
    });

    test('passes captured bearer token to remote logout', () async {
      notifier = buildNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.logout();
      await notifier.pendingBackgroundLogout;

      expect(auth.lastBearerToken, 'old-session-token');
      expect(auth.clearHeaderCalls, greaterThanOrEqualTo(1));
    });
  });
}
