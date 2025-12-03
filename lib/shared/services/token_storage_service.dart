import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing authentication tokens
class TokenStorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _profileCompletionTokenKey = 'profile_completion_token';
  static const String _refreshTokenKey = 'refresh_token';

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

  /// Clear all tokens
  Future<void> clearAllTokens() async {
    await Future.wait([
      _storage.delete(key: _authTokenKey),
      _storage.delete(key: _profileCompletionTokenKey),
      _storage.delete(key: _refreshTokenKey),
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

