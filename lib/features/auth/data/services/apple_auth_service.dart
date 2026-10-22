import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:lgbtindernew/core/services/app_logger.dart';

/// Result of a native Sign in with Apple prompt.
class AppleSignInResult {
  const AppleSignInResult({
    required this.identityToken,
    required this.rawNonce,
    this.authorizationCode,
    this.userIdentifier,
    this.givenName,
    this.familyName,
  });

  /// JWT signed by Apple; the backend verifies it against Apple's JWKS.
  final String identityToken;

  /// Raw nonce. Apple got its SHA-256; the backend checks the match.
  final String rawNonce;
  final String? authorizationCode;
  final String? userIdentifier;

  /// Apple sends the name only on the first authorization for this app.
  final String? givenName;
  final String? familyName;
}

/// Native Sign in with Apple (iOS) wrapper.
class AppleAuthService {
  static const _pendingNamePrefix = 'apple_signin_pending_name_';

  Future<bool> isAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Shows the Apple sheet. Returns null when the user cancels.
  Future<AppleSignInResult?> signIn() async {
    final rawNonce = generateNonce();
    final hashedNonce = sha256OfString(rawNonce);

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      AppLogger.error(
        'Sign in with Apple failed (${e.code})',
        tag: 'AppleAuthService',
        error: e,
      );
      rethrow;
    }

    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw StateError('Apple did not return an identity token.');
    }

    var givenName = _clean(credential.givenName);
    var familyName = _clean(credential.familyName);
    final userId = credential.userIdentifier;

    // Keep the first-login name until the backend has stored it, so a failed
    // request (network, server) doesn't lose it for good.
    if (userId != null && userId.isNotEmpty) {
      if (givenName != null || familyName != null) {
        await _savePendingName(userId, givenName, familyName);
      } else {
        final pending = await _readPendingName(userId);
        givenName = pending.$1;
        familyName = pending.$2;
      }
    }

    return AppleSignInResult(
      identityToken: identityToken,
      rawNonce: rawNonce,
      authorizationCode: credential.authorizationCode,
      userIdentifier: userId,
      givenName: givenName,
      familyName: familyName,
    );
  }

  /// Call after the backend accepted the sign-in.
  Future<void> clearPendingName(String? userIdentifier) async {
    if (userIdentifier == null || userIdentifier.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_pendingNamePrefix$userIdentifier');
    } catch (_) {}
  }

  static String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String sha256OfString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static String? _clean(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> _savePendingName(
    String userId,
    String? givenName,
    String? familyName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_pendingNamePrefix$userId',
        jsonEncode({'given': givenName, 'family': familyName}),
      );
    } catch (_) {}
  }

  Future<(String?, String?)> _readPendingName(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_pendingNamePrefix$userId');
      if (raw == null) return (null, null);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (map['given'] as String?, map['family'] as String?);
    } catch (_) {
      return (null, null);
    }
  }
}
