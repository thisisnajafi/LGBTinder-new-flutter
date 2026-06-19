import 'package:google_sign_in/google_sign_in.dart';

import 'package:lgbtindernew/core/constants/google_auth_config.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

/// Native Google Sign-In wrapper for obtaining ID tokens.
class GoogleAuthService {
  GoogleAuthService() : _googleSignIn = _buildGoogleSignIn();

  final GoogleSignIn _googleSignIn;

  static GoogleSignIn _buildGoogleSignIn() {
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId:
          GoogleAuthConfig.isConfigured ? GoogleAuthConfig.webClientId : null,
    );
  }

  /// Attempt silent sign-in and return a fresh ID token when available.
  Future<String?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.idToken;
    } catch (e, stack) {
      AppLogger.warning(
        'Google silent sign-in failed',
        tag: 'GoogleAuthService',
        error: e,
      );
      AppLogger.debug('Silent sign-in stack: $stack', tag: 'GoogleAuthService');
      return null;
    }
  }

  /// Interactive Google sign-in. Returns ID token or null if cancelled.
  Future<String?> signIn() async {
    if (!GoogleAuthConfig.isConfigured) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID is not configured. '
        'Pass --dart-define=GOOGLE_WEB_CLIENT_ID=... when building the app.',
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google did not return an ID token.');
      }
      return idToken;
    } catch (e, stack) {
      AppLogger.error(
        'Google sign-in failed',
        tag: 'GoogleAuthService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      AppLogger.warning(
        'Google sign-out failed',
        tag: 'GoogleAuthService',
        error: e,
      );
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      AppLogger.warning(
        'Google disconnect failed',
        tag: 'GoogleAuthService',
        error: e,
      );
    }
  }
}
