import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/constants/api_endpoints.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:lgbtindernew/features/auth/data/models/login_response.dart';
import 'package:lgbtindernew/features/auth/data/services/auth_service.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/shared/services/retry_service.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';
import 'package:mockito/mockito.dart';

class _FakeApiService extends Fake implements ApiService {
  String? lastEndpoint;
  dynamic lastData;
  bool? lastQueueIfOffline;
  ApiResponse<Map<String, dynamic>>? nextResponse;
  Object? nextError;

  @override
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
    Options? options,
    bool queueIfOffline = true,
    bool deduplicateIdempotent = false,
    RetryConfig? retryConfig,
  }) async {
    lastEndpoint = endpoint;
    lastData = data;
    lastQueueIfOffline = queueIfOffline;
    if (nextError != null) {
      throw nextError!;
    }
    return nextResponse! as ApiResponse<T>;
  }
}

class _FakeTokenStorage extends Fake implements TokenStorageService {
  String? authToken;
  String? profileCompletionToken;
  UserData? sessionUser;
  bool? sessionProfileCompleted;
  String? sessionUserState;

  @override
  Future<void> saveAuthToken(String token) async {
    authToken = token;
  }

  @override
  Future<void> saveProfileCompletionToken(String token) async {
    profileCompletionToken = token;
  }

  @override
  Future<void> clearProfileCompletionToken() async {
    profileCompletionToken = null;
  }

  @override
  Future<void> saveUserSession({
    required UserData user,
    bool profileCompleted = false,
    String? userState,
  }) async {
    sessionUser = user;
    sessionProfileCompleted = profileCompleted;
    sessionUserState = userState;
  }
}

class _FakeDioClient extends Fake implements DioClient {
  String? authToken;

  @override
  Future<void> updateAuthToken(String? token) async {
    authToken = token;
  }
}

void main() {
  late _FakeApiService api;
  late _FakeTokenStorage storage;
  late _FakeDioClient dio;
  late AuthService authService;

  setUp(() {
    api = _FakeApiService();
    storage = _FakeTokenStorage();
    dio = _FakeDioClient();
    authService = AuthService(api, storage, dio);
  });

  Map<String, dynamic> googleData({
    bool isNewUser = true,
    bool profileCompleted = false,
    String userState = 'profile_completion_required',
  }) {
    return {
      'user': {
        'id': 42,
        'first_name': 'New',
        'last_name': 'User',
        'email': 'newuser@example.com',
        'profile_completed': profileCompleted,
      },
      'user_id': 42,
      'email': 'newuser@example.com',
      'first_name': 'New',
      'token': 'google-sanctum-token',
      'token_type': 'Bearer',
      'is_new_user': isNewUser,
      'account_linked': false,
      'user_state': userState,
      'profile_completed': profileCompleted,
      'needs_profile_completion': !profileCompleted,
    };
  }

  group('AuthService.signInWithGoogle', () {
    test('posts the ID token and persists session for a new Google user',
        () async {
      api.nextResponse = ApiResponse<Map<String, dynamic>>(
        status: true,
        data: googleData(),
        message: 'Account created successfully with Google',
      );

      final result = await authService.signInWithGoogle(
        idToken: 'google-id-token',
        deviceName: 'Pixel 8',
      );

      expect(api.lastEndpoint, ApiEndpoints.googleAuth);
      expect(api.lastData, {
        'id_token': 'google-id-token',
        'device_name': 'Pixel 8',
      });
      expect(api.lastQueueIfOffline, isFalse);

      expect(result.status, isTrue);
      expect(result.isNewUser, isTrue);
      expect(result.token, 'google-sanctum-token');
      expect(result.email, 'newuser@example.com');
      expect(result.userState, 'profile_completion_required');
      expect(result.needsProfileCompletion, isTrue);

      expect(storage.authToken, 'google-sanctum-token');
      expect(storage.profileCompletionToken, 'google-sanctum-token');
      expect(dio.authToken, 'google-sanctum-token');
      expect(storage.sessionUser?.email, 'newuser@example.com');
      expect(storage.sessionProfileCompleted, isFalse);
      expect(storage.sessionUserState, 'profile_completion_required');
    });

    test('does not store a profile-completion token when profile is complete',
        () async {
      api.nextResponse = ApiResponse<Map<String, dynamic>>(
        status: true,
        data: googleData(
          isNewUser: false,
          profileCompleted: true,
          userState: 'ready_for_app',
        ),
        message: 'Successfully logged in with Google',
      );

      final result = await authService.signInWithGoogle(
        idToken: 'google-id-token',
      );

      expect(result.profileCompleted, isTrue);
      expect(result.userState, 'ready_for_app');
      expect(storage.authToken, 'google-sanctum-token');
      expect(storage.profileCompletionToken, isNull);
      expect(api.lastData, {'id_token': 'google-id-token'});
    });

    test('clears a leftover profile-completion token for a completed user',
        () async {
      storage.profileCompletionToken = 'stale-wizard-token';
      api.nextResponse = ApiResponse<Map<String, dynamic>>(
        status: true,
        data: googleData(
          isNewUser: false,
          profileCompleted: true,
          userState: 'ready_for_app',
        ),
        message: 'Successfully logged in with Google',
      );

      await authService.signInWithGoogle(idToken: 'google-id-token');

      expect(storage.profileCompletionToken, isNull);
    });

    test('throws when the backend returns no data', () async {
      api.nextResponse = ApiResponse<Map<String, dynamic>>(
        status: false,
        data: null,
        message: 'Invalid or expired Google token',
      );

      expect(
        () => authService.signInWithGoogle(idToken: 'bad-token'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid or expired Google token'),
          ),
        ),
      );
    });
  });
}
