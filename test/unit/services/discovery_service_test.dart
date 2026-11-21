/// Unit tests for DiscoveryService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/discover/data/services/discovery_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';
import 'package:lgbtindernew/shared/services/cache_service.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';
import 'package:lgbtindernew/features/payments/data/models/plan_limits.dart';

import 'discovery_service_test.mocks.dart';


class _FakeCacheService extends Fake implements CacheService {
  @override
  Future<T?> getCached<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? customExpiry,
  }) async =>
      null;

  @override
  Future<void> cacheData(
    String key,
    Map<String, dynamic> data, {
    Duration duration = CacheDuration.defaultDuration,
  }) async {}
}

class _FakePlanLimitsService extends Fake implements PlanLimitsService {
  @override
  Future<PlanLimits> getPlanLimits({bool forceRefresh = false}) async {
    throw Exception('plan limits unused in this unit test');
  }
}

@GenerateMocks([ApiService])
void main() {
  late DiscoveryService discoveryService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    discoveryService = DiscoveryService(
      mockApiService,
      _FakeCacheService(),
      _FakePlanLimitsService(),
    );
  });

  group('DiscoveryService', () {
    group('getNearbySuggestions', () {
      test('should return list of profiles on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'first_name': 'John',
              'last_name': 'Doe',
              'age': 28,
              'images': [],
            },
            {
              'id': 2,
              'first_name': 'Jane',
              'last_name': 'Smith',
              'age': 25,
              'images': [],
            },
          ],
        };

        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
          fromJson: anyNamed('fromJson'),
          options: anyNamed('options'),
          useCache: anyNamed('useCache'),
          forceRefresh: anyNamed('forceRefresh'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          status: true,
          data: responseData,
          message: 'Suggestions retrieved',
        ));

        // Act
        final result = await discoveryService.getNearbySuggestions();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[0].firstName, equals('John'));
        expect(result[1].id, equals(2));
        expect(result[1].firstName, equals('Jane'));
      });

      test('should return empty list when no suggestions', () async {
        // Arrange
        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
          fromJson: anyNamed('fromJson'),
          options: anyNamed('options'),
          useCache: anyNamed('useCache'),
          forceRefresh: anyNamed('forceRefresh'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          status: true,
          data: {'data': []},
          message: 'No suggestions',
        ));

        // Act
        final result = await discoveryService.getNearbySuggestions();

        // Assert
        expect(result, isNotNull);
        expect(result.isEmpty, isTrue);
      });

      test('should handle pagination parameters', () async {
        // Arrange
        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
          fromJson: anyNamed('fromJson'),
          options: anyNamed('options'),
          useCache: anyNamed('useCache'),
          forceRefresh: anyNamed('forceRefresh'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          status: true,
          data: {'data': []},
          message: 'Suggestions retrieved',
        ));

        // Act
        await discoveryService.getNearbySuggestions(page: 2, limit: 20);

        // Assert
        final captured = verify(mockApiService.get<dynamic>(
          any,
          queryParameters: captureAnyNamed('queryParameters'),
          fromJson: anyNamed('fromJson'),
          options: anyNamed('options'),
          useCache: anyNamed('useCache'),
          forceRefresh: anyNamed('forceRefresh'),
        )).captured;
        final params = captured.single as Map<String, dynamic>;
        expect(params['page'], 2);
        expect(params['limit'], 20);
      });
    });

    group('getAdvancedMatches', () {
      test('should return filtered profiles on successful call', () async {
        // Arrange
        final filters = {
          'min_age': 25,
          'max_age': 35,
          'gender_ids': [1, 2],
        };

        final responseData = {
          'data': [
            {
              'id': 1,
              'first_name': 'John',
              'last_name': 'Doe',
              'age': 28,
              'images': [],
            },
          ],
        };

        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
          fromJson: anyNamed('fromJson'),
          options: anyNamed('options'),
          useCache: anyNamed('useCache'),
          forceRefresh: anyNamed('forceRefresh'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          status: true,
          data: responseData,
          message: 'Matches retrieved',
        ));

        // Act
        final result = await discoveryService.getAdvancedMatches(filters: filters);

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(1));
        expect(result[0].id, equals(1));
      });

      test('should include filters in query parameters', () async {
        // Arrange
        final filters = {
          'min_age': 25,
          'max_age': 35,
        };

        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
          fromJson: anyNamed('fromJson'),
          options: anyNamed('options'),
          useCache: anyNamed('useCache'),
          forceRefresh: anyNamed('forceRefresh'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          status: true,
          data: {'data': []},
          message: 'Matches retrieved',
        ));

        // Act
        await discoveryService.getAdvancedMatches(filters: filters);

        // Assert
        final captured = verify(mockApiService.get<dynamic>(
          any,
          queryParameters: captureAnyNamed('queryParameters'),
          fromJson: anyNamed('fromJson'),
          options: anyNamed('options'),
          useCache: anyNamed('useCache'),
          forceRefresh: anyNamed('forceRefresh'),
        )).captured;
        final params = captured.single as Map<String, dynamic>;
        expect(params['min_age'], 25);
        expect(params['max_age'], 35);
      });
    });
  });
}

