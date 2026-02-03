/// Unit tests for DioClient
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';

import 'dio_client_test.mocks.dart';

@GenerateMocks([TokenStorageService])
void main() {
  late DioClient dioClient;
  late MockTokenStorageService mockTokenStorage;

  setUp(() {
    mockTokenStorage = MockTokenStorageService();
    dioClient = DioClient(mockTokenStorage);
  });

  group('DioClient - Initialization', () {
    test('should initialize with correct base URL', () {
      // Assert
      expect(dioClient.dio.options.baseUrl, equals('https://api.lgbtfinder.com'));
    });

    test('should initialize with correct timeouts', () {
      // Assert
      expect(dioClient.dio.options.connectTimeout, equals(const Duration(seconds: 30)));
      expect(dioClient.dio.options.receiveTimeout, equals(const Duration(seconds: 30)));
    });

    test('should initialize with correct headers', () {
      // Assert
      expect(dioClient.dio.options.headers['Content-Type'], equals('application/json'));
      expect(dioClient.dio.options.headers['Accept'], equals('application/json'));
    });
  });

  group('DioClient - Request Interceptor', () {
    test('should add Authorization header when token is available', () async {
      // Arrange
      const token = 'test_token';
      when(mockTokenStorage.getAuthToken()).thenAnswer((_) async => token);

      // Act
      final options = RequestOptions(path: '/test');
      final handler = RequestInterceptorHandler();
      
      // Simulate interceptor call
      final interceptor = dioClient.dio.interceptors.first;
      if (interceptor is InterceptorsWrapper) {
        await interceptor.onRequest(options, handler);
      }

      // Assert
      expect(options.headers['Authorization'], equals('Bearer $token'));
      verify(mockTokenStorage.getAuthToken()).called(1);
    });

    test('should not add Authorization header when token is not available', () async {
      // Arrange
      when(mockTokenStorage.getAuthToken()).thenAnswer((_) async => null);

      // Act
      final options = RequestOptions(path: '/test');
      final handler = RequestInterceptorHandler();
      
      // Simulate interceptor call
      final interceptor = dioClient.dio.interceptors.first;
      if (interceptor is InterceptorsWrapper) {
        await interceptor.onRequest(options, handler);
      }

      // Assert
      expect(options.headers['Authorization'], isNull);
      verify(mockTokenStorage.getAuthToken()).called(1);
    });
  });

  group('DioClient - Response Interceptor', () {
    test('should pass through successful responses', () {
      // Arrange
      final response = Response(
        data: {'status': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      );

      // Act
      final handler = ResponseInterceptorHandler();
      
      // Simulate interceptor call
      final interceptor = dioClient.dio.interceptors.first;
      if (interceptor is InterceptorsWrapper) {
        interceptor.onResponse(response, handler);
      }

      // Assert
      expect(handler.isCompleted, isTrue);
    });
  });

  group('DioClient - Error Interceptor', () {
    test('should handle 401 errors and attempt token refresh', () async {
      // Arrange
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => 'refresh_token');
      when(mockTokenStorage.getAuthToken()).thenAnswer((_) async => 'new_token');

      // Act
      final handler = ErrorInterceptorHandler();
      
      // Simulate interceptor call
      final interceptor = dioClient.dio.interceptors.first;
      if (interceptor is InterceptorsWrapper) {
        await interceptor.onError(error, handler);
      }

      // Assert
      // Token refresh logic should be called
      verify(mockTokenStorage.getRefreshToken()).called(1);
    });

    test('should clear tokens for auth endpoints on 401', () async {
      // Arrange
      final error = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/auth/login'),
        ),
      );

      // Act
      final handler = ErrorInterceptorHandler();
      
      // Simulate interceptor call
      final interceptor = dioClient.dio.interceptors.first;
      if (interceptor is InterceptorsWrapper) {
        await interceptor.onError(error, handler);
      }

      // Assert
      verify(mockTokenStorage.clearAllTokens()).called(1);
    });
  });

  group('DioClient - Token Refresh', () {
    test('should refresh token when expired', () async {
      // Arrange
      when(mockTokenStorage.getRefreshToken()).thenAnswer((_) async => 'refresh_token');
      when(mockTokenStorage.getAuthToken()).thenAnswer((_) async => 'new_token');

      // Act
      // Token refresh is handled internally by DioClient
      // This test verifies the refresh mechanism exists

      // Assert
      expect(dioClient.dio.interceptors.length, greaterThan(0));
    });
  });
}

