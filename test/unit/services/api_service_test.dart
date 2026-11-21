/// Unit tests for ApiService
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:lgbtindernew/shared/services/connectivity_service.dart';
import 'package:lgbtindernew/shared/services/cache_service.dart';
import 'package:lgbtindernew/shared/services/offline_queue_service.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';

import 'api_service_test.mocks.dart';


class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({
    this.statusCode = 200,
    this.body = '{"status":true,"data":{"id":1}}',
    this.throwable,
  });

  final int statusCode;
  final String body;
  final Object? throwable;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (throwable != null) {
      throw throwable!;
    }
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

@GenerateMocks([
  DioClient,
  ConnectivityService,
  CacheService,
  OfflineQueueService,
])
void main() {
  late ApiService apiService;
  late MockDioClient mockDioClient;
  late MockConnectivityService mockConnectivityService;
  late MockCacheService mockCacheService;
  late MockOfflineQueueService mockOfflineQueueService;
  late Dio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockConnectivityService = MockConnectivityService();
    mockCacheService = MockCacheService();
    mockOfflineQueueService = MockOfflineQueueService();
    mockDio = Dio();

    apiService = ApiService(
      mockDioClient,
      mockConnectivityService,
      mockCacheService,
      mockOfflineQueueService,
    );

    when(mockDioClient.dio).thenReturn(mockDio);
  });

  group('ApiService - GET requests', () {
    test('should return cached data when available and online', () async {
      // Arrange
      const endpoint = '/test';
      final cachedData = {'id': 1, 'name': 'Test'};
      
      when(mockConnectivityService.isOnline).thenReturn(true);
      when(mockCacheService.getCached(any, any))
          .thenAnswer((_) async => cachedData);

      // Act
      final result = await apiService.get<Map<String, dynamic>>(
        endpoint,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(cachedData));
      verify(mockCacheService.getCached(any, any)).called(1);
    });

    test('should return cached data when offline', () async {
      // Arrange
      const endpoint = '/test';
      final cachedData = {'id': 1, 'name': 'Test'};
      
      when(mockConnectivityService.isOnline).thenReturn(false);
      when(mockCacheService.getCached(any, any))
          .thenAnswer((_) async => cachedData);

      // Act
      final result = await apiService.get<Map<String, dynamic>>(
        endpoint,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(cachedData));
    });

    test('should throw ApiError when offline and no cache available', () async {
      // Arrange
      const endpoint = '/test';
      
      when(mockConnectivityService.isOnline).thenReturn(false);
      when(mockCacheService.getCached(any, any))
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => apiService.get<Map<String, dynamic>>(endpoint),
        throwsA(isA<ApiError>()),
      );
    });
  });

  group('ApiService - POST requests', () {
    test('should handle successful POST request', () async {
      // Arrange
      const endpoint = '/test';
      final requestData = {'name': 'Test'};
      
      when(mockConnectivityService.isOnline).thenReturn(true);
      mockDio.httpClientAdapter = _ScriptedAdapter();

      // Act
      final result = await apiService.post<Map<String, dynamic>>(
        endpoint,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?['id'], equals(1));
    });

    test('should queue request when offline', () async {
      // Arrange
      const endpoint = '/test';
      final requestData = {'name': 'Test'};
      
      when(mockConnectivityService.isOnline).thenReturn(false);
      when(mockOfflineQueueService.queueRequest(any))
          .thenAnswer((_) async => Future.value());

      // Act & Assert — queued, then surfaced as a no-internet ApiError
      await expectLater(
        apiService.post<Map<String, dynamic>>(
          endpoint,
          data: requestData,
        ),
        throwsA(isA<ApiError>()),
      );
      verify(mockOfflineQueueService.queueRequest(any)).called(1);
    });
  });

  group('ApiService - PUT requests', () {
    test('should handle successful PUT request', () async {
      // Arrange
      const endpoint = '/test/1';
      final requestData = {'name': 'Updated'};
      
      when(mockConnectivityService.isOnline).thenReturn(true);
      mockDio.httpClientAdapter = _ScriptedAdapter(
        body: '{"status":true,"data":{"id":1,"name":"Updated"}}',
      );

      // Act
      final result = await apiService.put<Map<String, dynamic>>(
        endpoint,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?['name'], equals('Updated'));
    });
  });

  group('ApiService - DELETE requests', () {
    test('should handle successful DELETE request', () async {
      // Arrange
      const endpoint = '/test/1';
      
      when(mockConnectivityService.isOnline).thenReturn(true);
      mockDio.httpClientAdapter = _ScriptedAdapter(body: '{"status":true}');

      // Act
      final result = await apiService.delete<Map<String, dynamic>>(
        endpoint,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Assert
      expect(result.isSuccess, isTrue);
    });
  });

  group('ApiService - Error handling', () {
    test('should handle network errors', () async {
      // Arrange
      const endpoint = '/test';
      
      when(mockConnectivityService.isOnline).thenReturn(true);
      when(mockCacheService.getCached(any, any)).thenAnswer((_) async => null);
      mockDio.httpClientAdapter = _ScriptedAdapter(
        throwable: DioException(
          requestOptions: RequestOptions(path: endpoint),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act & Assert
      expect(
        () => apiService.get<Map<String, dynamic>>(endpoint),
        throwsA(isA<ApiError>()),
      );
    });

    test('should handle 401 unauthorized errors', () async {
      // Arrange
      const endpoint = '/test';
      
      when(mockConnectivityService.isOnline).thenReturn(true);
      when(mockCacheService.getCached(any, any)).thenAnswer((_) async => null);
      mockDio.httpClientAdapter = _ScriptedAdapter(
        statusCode: 401,
        body: '{"message":"Unauthorized"}',
      );

      // Act & Assert
      expect(
        () => apiService.get<Map<String, dynamic>>(endpoint),
        throwsA(isA<ApiError>()),
      );
    });
  });
}

