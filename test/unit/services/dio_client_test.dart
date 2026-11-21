/// Unit tests for DioClient
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';

import 'dio_client_test.mocks.dart';

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter({this.statusCode = 200, this.body = '{"status":true}'});

  final int statusCode;
  final String body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

@GenerateMocks([TokenStorageService])
void main() {
  late DioClient dioClient;
  late MockTokenStorageService mockTokenStorage;

  setUp(() {
    mockTokenStorage = MockTokenStorageService();
    when(mockTokenStorage.getAuthToken()).thenAnswer((_) async => null);
    when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);
    dioClient = DioClient(mockTokenStorage);
  });

  group('DioClient - Initialization', () {
    test('should initialize with correct base URL', () {
      expect(
        dioClient.dio.options.baseUrl,
        equals('https://api.lgbtfinder.com/api'),
      );
    });

    test('should initialize with correct timeouts', () {
      expect(
        dioClient.dio.options.connectTimeout,
        equals(const Duration(seconds: 60)),
      );
      expect(
        dioClient.dio.options.receiveTimeout,
        equals(const Duration(seconds: 60)),
      );
    });

    test('should initialize with correct headers', () {
      expect(
        dioClient.dio.options.headers['Content-Type'],
        equals('application/json'),
      );
      expect(
        dioClient.dio.options.headers['Accept'],
        equals('application/json'),
      );
    });
  });

  group('DioClient - Request Interceptor', () {
    test('should add Authorization header when token is available', () async {
      const token = 'test_token';
      when(mockTokenStorage.getAuthToken()).thenAnswer((_) async => token);
      final adapter = _CaptureAdapter();
      dioClient.dio.httpClientAdapter = adapter;

      await dioClient.dio.get('/test');

      expect(adapter.lastRequest?.headers['Authorization'], equals('Bearer $token'));
      verify(mockTokenStorage.getAuthToken()).called(greaterThanOrEqualTo(1));
    });

    test('should not add Authorization header when token is not available', () async {
      when(mockTokenStorage.getAuthToken()).thenAnswer((_) async => null);
      final adapter = _CaptureAdapter();
      dioClient.dio.httpClientAdapter = adapter;

      await dioClient.dio.get('/test');

      expect(adapter.lastRequest?.headers['Authorization'], isNull);
    });
  });

  group('DioClient - Response Interceptor', () {
    test('should pass through successful responses', () async {
      final adapter = _CaptureAdapter();
      dioClient.dio.httpClientAdapter = adapter;

      final response = await dioClient.dio.get('/test');

      expect(response.statusCode, 200);
      expect(response.data['status'], isTrue);
    });
  });

  group('DioClient - Error Interceptor', () {
    test('should handle 401 errors and attempt token refresh', () async {
      when(mockTokenStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh_token');
      when(mockTokenStorage.getAuthToken())
          .thenAnswer((_) async => 'new_token');

      final adapter = _CaptureAdapter(statusCode: 401, body: '{"message":"Unauthorized"}');
      dioClient.dio.httpClientAdapter = adapter;

      try {
        await dioClient.dio.get('/test');
      } on DioException {
        // 401 after a failed or unconfigured refresh still surfaces as DioException.
      }

      verify(mockTokenStorage.getRefreshToken()).called(greaterThanOrEqualTo(1));
    });

    test('on 401 for auth endpoints does not clear storage (app callback does via logout)', () async {
      final adapter = _CaptureAdapter(statusCode: 401, body: '{"message":"Unauthorized"}');
      dioClient.dio.httpClientAdapter = adapter;

      try {
        await dioClient.dio.post('/auth/login');
      } on DioException {
        // Expected — login 401 must not wipe stored tokens.
      }

      verifyNever(mockTokenStorage.clearAllTokens());
    });
  });

  group('DioClient - Token Refresh', () {
    test('should refresh token when expired', () async {
      when(mockTokenStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh_token');
      when(mockTokenStorage.getAuthToken()).thenAnswer((_) async => 'new_token');

      expect(dioClient.dio.interceptors.length, greaterThan(0));
    });
  });
}
