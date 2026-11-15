// Provider: AuthProvider
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../data/models/login_response.dart';
import '../data/services/auth_service.dart';
import '../data/services/google_auth_service.dart';
import '../../../shared/services/token_storage_service.dart';
import '../../../shared/services/onboarding_service.dart';
import '../../../shared/services/push_notification_service.dart';
import '../../../shared/services/agora_service.dart';
import '../../../core/cache/cache_invalidator.dart';
import '../../../core/providers/api_providers.dart';
import 'auth_service_provider.dart';
import '../../../core/errors/user_error_message.dart';
import '../../calls/data/services/call_kit_service.dart';

/// Auth Provider State
class AuthProviderState {
  final bool isAuthenticated;
  final bool isEmailVerified;
  final bool isProfileComplete;
  final bool hasCompletedOnboarding;
  final UserData? user;
  final bool isLoading;
  final String? errorMessage;

  AuthProviderState({
    this.isAuthenticated = false,
    this.isEmailVerified = false,
    this.isProfileComplete = false,
    this.hasCompletedOnboarding = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthProviderState copyWith({
    bool? isAuthenticated,
    bool? isEmailVerified,
    bool? isProfileComplete,
    bool? hasCompletedOnboarding,
    UserData? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthProviderState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Auth Provider Notifier
class AuthProviderNotifier extends StateNotifier<AuthProviderState> {
  final AuthService _authService;
  final TokenStorageService _tokenStorage;
  final OnboardingService _onboardingService;
  final Future<void> Function() _onLogoutCachePurge;
  final void Function() _onLogoutInMemoryReset;
  final GoogleAuthService? _googleAuthService;

  /// Local FCM cleanup (topics + device token). Receives a `superseded`
  /// probe so a re-login that races the token delete can re-register.
  /// Null on hosts without Firebase (desktop / unit tests).
  final Future<void> Function(bool Function() superseded)? _onLogoutPushCleanup;

  /// Bumped on every logout start and successful login so a late background
  /// logout cannot tear down a newer session.
  int _sessionEpoch = 0;

  bool _optimisticLogoutInFlight = false;

  /// Raw (un-timed-out) background cache purge. [login] waits for it so a
  /// purge that started before re-login can never delete the new user's data.
  Future<void>? _backgroundPurge;

  /// Last scheduled background logout (for tests).
  @visibleForTesting
  Future<void>? pendingBackgroundLogout;

  AuthProviderNotifier(
    this._authService,
    this._tokenStorage,
    this._onboardingService,
    this._onLogoutCachePurge,
    this._onLogoutInMemoryReset, {
    GoogleAuthService? googleAuthService,
    Future<void> Function(bool Function() superseded)? onLogoutPushCleanup,
  })  : _googleAuthService = googleAuthService,
        _onLogoutPushCleanup = onLogoutPushCleanup,
        super(AuthProviderState()) {
    // Defer so provider creation never blocks; avoids async work during first read
    Future.microtask(() => checkAuthStatus());
  }

  /// Check authentication status
  Future<void> checkAuthStatus() async {
    // A logout / login that lands while storage is being read wins: this
    // check must not resurrect (or wipe) the session it raced with.
    final epochAtStart = _sessionEpoch;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final isAuthenticated = await _tokenStorage.isAuthenticated();
      final hasCompletedOnboarding =
          await _onboardingService.isOnboardingCompleted();
      if (_sessionEpoch != epochAtStart) return;

      if (!isAuthenticated) {
        state = state.copyWith(
          isAuthenticated: false,
          user: null,
          hasCompletedOnboarding: hasCompletedOnboarding,
          isLoading: false,
        );
        return;
      }

      final session = await _tokenStorage.getUserSession();
      if (_sessionEpoch != epochAtStart) return;
      state = state.copyWith(
        isAuthenticated: true,
        user: session?.user,
        isProfileComplete: session?.profileCompleted ?? false,
        isEmailVerified: session?.userState != 'email_verification_required',
        hasCompletedOnboarding: hasCompletedOnboarding,
        isLoading: false,
      );
    } catch (e, stack) {
      AppLogger.error(
        'Auth check failed',
        tag: 'AuthProvider',
        error: e,
        stackTrace: stack,
      );
      if (_sessionEpoch != epochAtStart) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: userErrorMessage(e),
      );
    }
  }

  /// Login user
  Future<void> login(LoginResponse loginResponse) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Invalidate any in-flight background logout before purging for the new user.
      _sessionEpoch++;

      // A background purge that already started cannot be cancelled. Let it
      // finish first so it never runs past this point and deletes data that
      // belongs to the session being created.
      final inFlightPurge = _backgroundPurge;
      if (inFlightPurge != null) {
        try {
          await inFlightPurge.timeout(_loginPurgeWait);
        } catch (e) {
          AppLogger.warning(
            'Previous session purge still running at login',
            tag: 'AuthProvider',
            error: e,
          );
        }
      }

      // Clear any prior user's chat and private cached data before starting a new session.
      await _onLogoutCachePurge();

      // Update state with login response
      state = state.copyWith(
        isAuthenticated: true,
        isEmailVerified:
            loginResponse.userState != 'email_verification_required',
        isProfileComplete: loginResponse.profileCompleted,
        user: loginResponse.user,
        isLoading: false,
      );
    } catch (e, stack) {
      AppLogger.error(
        'Login state update failed',
        tag: 'AuthProvider',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: userErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Optimistic logout: clear local session immediately, network/cleanup in background.
  ///
  /// [silent] when true (e.g. from 401 handler): same local clear, no error toast path.
  /// Returns as soon as local auth is gone so UI can navigate within one frame.
  Future<void> logout({bool silent = false}) async {
    if (silent) {
      AppLogger.debug('Silent optimistic logout', tag: 'AuthProvider');
    }

    // Double-tap / re-entrant while already logged out with no leftover token.
    if (!state.isAuthenticated && _optimisticLogoutInFlight) {
      return;
    }
    if (!state.isAuthenticated) {
      final leftover = await _tokenStorage.getAuthToken();
      if (leftover == null || leftover.isEmpty) {
        return;
      }
      // Another logout may have started while storage was being read.
      if (_optimisticLogoutInFlight) return;
    }

    _optimisticLogoutInFlight = true;
    final epochAtStart = ++_sessionEpoch;

    // Critical path, step 1 (synchronous — no await before this point for a
    // signed-in user): in-memory auth is gone in the same microtask as the
    // tap, so a second tap is a no-op and listeners leave immediately.
    state = AuthProviderState(
      isAuthenticated: false,
      isEmailVerified: false,
      isProfileComplete: false,
      hasCompletedOnboarding: false,
      user: null,
      isLoading: false,
    );
    try {
      _authService.clearInMemoryAuthHeader();
    } catch (e) {
      AppLogger.warning(
        'In-memory auth header clear failed',
        tag: 'AuthProvider',
        error: e,
      );
    }

    // Step 2 (fast local storage only): capture what the server call needs,
    // then drop the persisted session so route guards see "logged out".
    String? capturedToken;
    String? capturedDeviceToken;
    try {
      capturedToken =
          await _tokenStorage.getAuthToken().timeout(_localStorageTimeout);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to capture logout credentials',
        tag: 'AuthProvider',
        error: e,
      );
      AppLogger.debug('Capture stack: $stack', tag: 'AuthProvider');
    }
    try {
      capturedDeviceToken = PushNotificationService().fcmToken;
    } catch (_) {
      // Firebase not available on this host (tests / desktop).
    }

    try {
      // Bounded: a stuck keystore must not hold the UI on the old screen.
      await _tokenStorage.clearAllTokens().timeout(_localStorageTimeout);
    } catch (e, stack) {
      AppLogger.error(
        'Local token clear failed',
        tag: 'AuthProvider',
        error: e,
        stackTrace: stack,
      );
    }

    try {
      _onLogoutInMemoryReset();
    } catch (e, stack) {
      AppLogger.warning(
        'In-memory session reset failed',
        tag: 'AuthProvider',
        error: e,
      );
      AppLogger.debug('Reset stack: $stack', tag: 'AuthProvider');
    }

    final background = _runBackgroundLogout(
      epochAtStart: epochAtStart,
      capturedToken: capturedToken,
      capturedDeviceToken: capturedDeviceToken,
    );
    pendingBackgroundLogout = background;
    unawaited(background);
  }

  Future<void> _runBackgroundLogout({
    required int epochAtStart,
    required String? capturedToken,
    required String? capturedDeviceToken,
  }) async {
    const stepTimeout = Duration(seconds: 7);
    try {
      await _authService
          .logout(
            bearerToken: capturedToken,
            deviceToken: capturedDeviceToken,
          )
          .timeout(stepTimeout);
    } catch (e, stack) {
      AppLogger.warning(
        'Background remote logout failed (ignored)',
        tag: 'AuthProvider',
        error: e,
      );
      AppLogger.debug('Remote logout stack: $stack', tag: 'AuthProvider');
    }

    // Remote revoke used the captured token only; safe even after re-login.
    // Local teardown below must not run if a newer session exists.
    if (!await _mayContinueBackgroundCleanup(epochAtStart, capturedToken)) {
      _finishBackgroundLogout(epochAtStart);
      return;
    }

    // Local FCM token delete. It used to run unguarded inside the remote
    // step; a re-login during a slow network then lost its push registration
    // (no chat / incoming-call pushes for the whole new session).
    final pushCleanup = _onLogoutPushCleanup;
    if (pushCleanup != null) {
      await _runGuardedStep('Push cleanup', stepTimeout, () async {
        await pushCleanup(() => _sessionEpoch != epochAtStart);
      });

      if (!await _mayContinueBackgroundCleanup(epochAtStart, capturedToken)) {
        _finishBackgroundLogout(epochAtStart);
        return;
      }
    }

    await _runGuardedStep('Google sign-out', stepTimeout, () async {
      await _googleAuthService?.signOut();
    });

    if (!await _mayContinueBackgroundCleanup(epochAtStart, capturedToken)) {
      _finishBackgroundLogout(epochAtStart);
      return;
    }

    // CallKit / Agora only exist on mobile; desktop widget tests hang on
    // missing platform channels if we invoke them unconditionally.
    if (_supportsNativeCallTeardown) {
      await _runGuardedStep('CallKit endAllCalls', stepTimeout, () async {
        await CallKitService.instance.endAllCalls();
      });

      await _runGuardedStep('Agora dispose', stepTimeout, () async {
        await AgoraService().dispose();
      });
    }

    if (!await _mayContinueBackgroundCleanup(epochAtStart, capturedToken)) {
      _finishBackgroundLogout(epochAtStart);
      return;
    }

    await _runGuardedStep('Cache purge', stepTimeout, () {
      // Keep the raw future: the step timeout stops *waiting*, it does not
      // stop the purge. [login] awaits this before activating a new user.
      final purge = Future<void>.sync(_onLogoutCachePurge);
      _backgroundPurge = purge;
      // Second future on purpose: errors surface through the guarded step,
      // this branch only clears the handle.
      unawaited(
        purge.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
          if (identical(_backgroundPurge, purge)) _backgroundPurge = null;
        }),
      );
      return purge;
    });

    _finishBackgroundLogout(epochAtStart);
  }

  /// Only the newest logout may clear the in-flight flag; an older run that
  /// finishes late must not re-open the double-tap guard of a newer one.
  void _finishBackgroundLogout(int epochAtStart) {
    if (_sessionEpoch == epochAtStart) {
      _optimisticLogoutInFlight = false;
    }
  }

  /// How long [login] waits for a purge the previous logout already started.
  static const Duration _loginPurgeWait = Duration(seconds: 4);

  /// Upper bound for each secure-storage step on the logout critical path
  /// (normally a few milliseconds).
  static const Duration _localStorageTimeout = Duration(seconds: 2);

  /// False when the user logged in again (epoch bump or different bearer token).
  Future<bool> _mayContinueBackgroundCleanup(
    int epochAtStart,
    String? capturedToken,
  ) async {
    if (_sessionEpoch != epochAtStart) {
      AppLogger.info(
        'Skipping background logout cleanup: newer session epoch',
        tag: 'AuthProvider',
      );
      return false;
    }
    try {
      final current = await _tokenStorage.getAuthToken();
      if (current != null &&
          current.isNotEmpty &&
          capturedToken != null &&
          capturedToken.isNotEmpty &&
          current != capturedToken) {
        AppLogger.info(
          'Skipping background logout cleanup: newer session token',
          tag: 'AuthProvider',
        );
        return false;
      }
      if (current != null &&
          current.isNotEmpty &&
          (capturedToken == null || capturedToken.isEmpty)) {
        AppLogger.info(
          'Skipping background logout cleanup: session token present',
          tag: 'AuthProvider',
        );
        return false;
      }
    } catch (_) {
      // If we cannot read storage, prefer skipping destructive cleanup.
      return false;
    }
    return true;
  }

  Future<void> _runGuardedStep(
    String label,
    Duration timeout,
    Future<void> Function() step,
  ) async {
    try {
      await step().timeout(timeout);
    } catch (e, stack) {
      AppLogger.warning(
        'Background logout step failed: $label',
        tag: 'AuthProvider',
        error: e,
      );
      AppLogger.debug('$label stack: $stack', tag: 'AuthProvider');
    }
  }

  static bool get _supportsNativeCallTeardown => supportsNativeSessionTeardown;

  /// True on Android / iOS, where CallKit, Agora and Firebase Messaging have
  /// real platform channels.
  static bool get supportsNativeSessionTeardown {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Update profile completion status
  void updateProfileStatus(bool isComplete) {
    state = state.copyWith(isProfileComplete: isComplete);
  }

  /// Update email verification status
  void updateEmailVerificationStatus(bool isVerified) {
    state = state.copyWith(isEmailVerified: isVerified);
  }

  /// Update onboarding completion status
  Future<void> updateOnboardingStatus(bool isCompleted) async {
    if (isCompleted) {
      await _onboardingService.markOnboardingCompleted();
    } else {
      await _onboardingService.resetOnboardingStatus();
    }

    state = state.copyWith(hasCompletedOnboarding: isCompleted);
  }

  /// Update user data
  void updateUser(UserData? user) {
    state = state.copyWith(user: user);
  }
}

/// Auth Provider
final authProvider =
    StateNotifierProvider<AuthProviderNotifier, AuthProviderState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  final onboardingService = OnboardingService();
  final googleAuth = ref.watch(googleAuthServiceProvider);
  final invalidator = ref.read(cacheInvalidatorProvider);

  return AuthProviderNotifier(
    authService,
    tokenStorage,
    onboardingService,
    () => invalidator.purgeAll(),
    () => invalidator.resetInMemorySessionState(),
    googleAuthService: googleAuth,
    // Firebase Messaging only exists on mobile; desktop/widget tests would
    // hang on the missing platform channel.
    onLogoutPushCleanup: AuthProviderNotifier.supportsNativeSessionTeardown
        ? (superseded) => PushNotificationService()
            .clearOnLogout(sessionSuperseded: superseded)
        : null,
  );
});
