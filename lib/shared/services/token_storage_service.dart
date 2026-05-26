import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/stored_user_session.dart';
import '../../features/auth/data/models/login_response.dart';

/// Service for securely storing authentication tokens and user session data.
class TokenStorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _profileCompletionTokenKey = 'profile_completion_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userSessionKey = 'user_session';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Save profile completion token
  Future<void> saveProfileCompletionToken(String token) async {
    await _storage.write(key: _profileCompletionTokenKey, value: token);
  }

  /// Get profile completion token
  Future<String?> getProfileCompletionToken() async {
    return await _storage.read(key: _profileCompletionTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Save logged-in user profile and auth metadata (secure storage).
  Future<void> saveUserSession({
    required UserData user,
    bool profileCompleted = false,
    String? userState,
  }) async {
    final session = StoredUserSession(
      user: user,
      profileCompleted: profileCompleted,
      userState: userState,
    );
    await _storage.write(
      key: _userSessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  /// Load persisted user session, if any.
  Future<StoredUserSession?> getUserSession() async {
    final raw = await _storage.read(key: _userSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StoredUserSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clear persisted user session only.
  Future<void> clearUserSession() async {
    await _storage.delete(key: _userSessionKey);
  }

  /// Clear all tokens and user session.
  Future<void> clearAllTokens() async {
    await Future.wait([
      _storage.delete(key: _authTokenKey),
      _storage.delete(key: _profileCompletionTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userSessionKey),
    ]);
  }

  /// Clear only auth token
  Future<void> clearAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  /// Clear only profile completion token
  Future<void> clearProfileCompletionToken() async {
    await _storage.delete(key: _profileCompletionTokenKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}

