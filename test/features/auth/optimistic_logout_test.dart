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

    test('redacts secrets inside lists and under key variants', () {
      final redacted = redactSensitiveBody({
        'Authorization': 'Bearer abc.def',
        'current_password': 'old',
        'new_password': 'new',
        'profile_completion_token': 'pct',
        'device_token': 'fcm-token',
        'client_secret': 'shh',
        'code': '123456',
        'devices': [
          {'device_token': 'fcm-2', 'platform': 'android'},
        ],
      });

      expect(redacted!['Authorization'], '***');
      expect(redacted['current_password'], '***');
      expect(redacted['new_password'], '***');
      expect(redacted['profile_completion_token'], '***');
      expect(redacted['device_token'], '***');
      expect(redacted['client_secret'], '***');
      // Not a credential field name: left as-is (documented in the report).
      expect(redacted['code'], '123456');
      final device = (redacted['devices'] as List).single as Map;
      expect(device['device_token'], '***');
      expect(device['platform'], 'android');
      expect(redacted.toString(), isNot(contains('fcm-2')));
      expect(redacted.toString(), isNot(contains('abc.def')));
    });

    test('does not mutate the request body it is given', () {
      final body = {
        'password': 'secret',
        'items': [
          {'token': 't'},
        ],
      };
      redactSensitiveBody(body);
      expect(body['password'], 'secret');
      expect(((body['items'] as List).single as Map)['token'], 't');
    });
  });

  group('redactSensitiveUrl', () {
    test('masks token-like query parameters, keeps the rest', () {
      final url = redactSensitiveUrl(
        'https://api.test/auth/verify?token=abc123&email=a%40b.com&page=2',
      );
      expect(url, isNot(contains('abc123')));
      expect(url, contains('page=2'));
      expect(url, contains('email='));
    });

    test('leaves URLs without secrets untouched', () {
      const plain = 'https://api.test/users?page=2&per_page=20';
      expect(redactSensitiveUrl(plain), plain);
      expect(redactSensitiveUrl('/users/5'), '/users/5');
    });
  });

  group('DioClient.shouldEndSessionFor (stale-session 401 guard)', () {
    test('401 for the current session ends it', () {
      expect(
        DioClient.shouldEndSessionFor(
          failedRequestBearer: 'tok-b',
          currentToken: 'tok-b',
        ),
        isTrue,
      );
    });

    test('late 401 from the previous session keeps the new login', () {
      expect(
        DioClient.shouldEndSessionFor(
          failedRequestBearer: 'tok-a',
          currentToken: 'tok-b',
        ),
        isFalse,
      );
    });

    test('nothing to end when already logged out', () {
      expect(
        DioClient.shouldEndSessionFor(
          failedRequestBearer: 'tok-a',
          currentToken: null,
        ),
        isFalse,
      );
      expect(
        DioClient.shouldEndSessionFor(
          failedRequestBearer: 'tok-a',
          currentToken: '',
        ),
        isFalse,
      );
    });

    test('request without a bearer falls back to the stored session', () {
      expect(
        DioClient.shouldEndSessionFor(
          failedRequestBearer: null,
          currentToken: 'tok-b',
        ),
        isTrue,
      );
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
      Future<void> Function(bool Function() superseded)? onPushCleanup,
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
        onLogoutPushCleanup: onPushCleanup,
      );
    }

    LoginResponse loginAs(String token) => LoginResponse(
          token: token,
          profileCompleted: true,
          needsProfileCompletion: false,
          userState: 'ready',
          user: UserData(
            id: 99,
            firstName: 'New',
            lastName: 'User',
            email: 'new@test.com',
          ),
        );

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

    test('state is logged out in the same turn as the tap', () async {
      final hang = Completer<void>();
      notifier = buildNotifier(logoutCompleter: hang);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isAuthenticated, isTrue);

      // Not awaited: nothing asynchronous may sit before the state flip.
      final pending = notifier.logout();
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.user, isNull);
      expect(auth.clearHeaderCalls, 1);

      await pending;
      hang.complete();
      await notifier.pendingBackgroundLogout;
    });

    test('two taps in the same frame run a single logout', () async {
      final hang = Completer<void>();
      notifier = buildNotifier(logoutCompleter: hang);
      await Future<void>.delayed(Duration.zero);

      final first = notifier.logout();
      final second = notifier.logout();
      await Future.wait([first, second]);

      hang.complete();
      await notifier.pendingBackgroundLogout;

      expect(auth.logoutCalls, 1);
      expect(events.where((e) => e == 'in_memory_reset').length, 1);
      expect(events.where((e) => e == 'purge').length, 1);
    });

    test('push cleanup runs once after the server call, for this session',
        () async {
      final seen = <bool>[];
      notifier = buildNotifier(
        onPushCleanup: (superseded) async {
          events.add('push_cleanup');
          seen.add(superseded());
        },
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.logout();
      await notifier.pendingBackgroundLogout;

      expect(seen, [false]);
      expect(auth.logoutCalls, 1);
      expect(
        events.indexOf('push_cleanup'),
        lessThan(events.indexOf('purge')),
      );
    });

    test('re-login during the server call skips push cleanup entirely',
        () async {
      final hang = Completer<void>();
      var pushCleanups = 0;
      notifier = buildNotifier(
        logoutCompleter: hang,
        onPushCleanup: (_) async {
          pushCleanups++;
        },
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.logout();
      await storage.saveAuthToken('new-session-token');
      await notifier.login(loginAs('new-session-token'));

      hang.complete();
      await notifier.pendingBackgroundLogout;

      // Deleting the FCM token now would silence pushes for the new user.
      expect(pushCleanups, 0);
      expect(notifier.state.isAuthenticated, isTrue);
    });

    test('re-login while push cleanup is running is reported as superseded',
        () async {
      final cleanupStarted = Completer<void>();
      final releaseCleanup = Completer<void>();
      bool? supersededAfterDelete;
      notifier = buildNotifier(
        onPushCleanup: (superseded) async {
          cleanupStarted.complete();
          await releaseCleanup.future;
          supersededAfterDelete = superseded();
        },
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.logout();
      await cleanupStarted.future;

      await storage.saveAuthToken('new-session-token');
      await notifier.login(loginAs('new-session-token'));
      final purgesAfterLogin = events.where((e) => e == 'purge').length;

      releaseCleanup.complete();
      await notifier.pendingBackgroundLogout;

      // The push service uses this to register a fresh token for the new
      // session instead of leaving it without one.
      expect(supersededAfterDelete, isTrue);
      expect(await storage.getAuthToken(), 'new-session-token');
      expect(events.where((e) => e == 'purge').length, purgesAfterLogin);
    });

    test('login waits for a purge the previous logout already started',
        () async {
      final purgeStarted = Completer<void>();
      final releasePurge = Completer<void>();
      var purgeRuns = 0;
      notifier = buildNotifier(
        onPurge: () async {
          purgeRuns++;
          final run = purgeRuns;
          events.add('purge_start_$run');
          if (run == 1) {
            purgeStarted.complete();
            await releasePurge.future;
          }
          events.add('purge_end_$run');
        },
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.logout();
      await purgeStarted.future;

      await storage.saveAuthToken('new-session-token');
      final login = notifier.login(loginAs('new-session-token'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // The old purge is still deleting: the new session is not live yet and
      // has not started its own purge underneath it.
      expect(events, isNot(contains('purge_start_2')));
      expect(notifier.state.isAuthenticated, isFalse);

      releasePurge.complete();
      await login;
      await notifier.pendingBackgroundLogout;

      expect(
        events.where((e) => e.startsWith('purge_')).toList(),
        ['purge_start_1', 'purge_end_1', 'purge_start_2', 'purge_end_2'],
      );
      expect(notifier.state.isAuthenticated, isTrue);
      expect(await storage.getAuthToken(), 'new-session-token');
    });

    test('auth check that races a logout cannot bring the session back',
        () async {
      final hang = Completer<void>();
      notifier = buildNotifier(logoutCompleter: hang);
      await Future<void>.delayed(Duration.zero);

      // Starts reading storage while the token is still there…
      final check = notifier.checkAuthStatus();
      // …and the user logs out before it finishes.
      await notifier.logout();
      await check;

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.user, isNull);

      hang.complete();
      await notifier.pendingBackgroundLogout;
    });
  });
}
