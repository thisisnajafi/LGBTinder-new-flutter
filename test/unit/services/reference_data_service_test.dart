/// Unit tests for ReferenceDataService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/reference_data/data/services/reference_data_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/features/reference_data/data/models/reference_item.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'reference_data_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late ReferenceDataService referenceDataService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    referenceDataService = ReferenceDataService(mockApiService);
  });

  group('ReferenceDataService', () {
    group('getCountries', () {
      test('should return list of countries on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {'id': 1, 'name': 'United States', 'code': 'US'},
            {'id': 2, 'name': 'Canada', 'code': 'CA'},
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Countries retrieved',
            ));

        // Act
        final result = await referenceDataService.getCountries();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[0].name, equals('United States'));
        expect(result[1].id, equals(2));
        expect(result[1].name, equals('Canada'));
      });

      test('should return empty list when no countries', () async {
        // Arrange
        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: {'data': []},
              message: 'No countries',
            ));

        // Act
        final result = await referenceDataService.getCountries();

        // Assert
        expect(result, isNotNull);
        expect(result.isEmpty, isTrue);
      });
    });

    group('getCitiesByCountry', () {
      test('should return list of cities for country on successful call', () async {
        // Arrange
        const countryId = 1;
        final responseData = {
          'data': [
            {'id': 1, 'name': 'New York', 'country_id': 1},
            {'id': 2, 'name': 'Los Angeles', 'country_id': 1},
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Cities retrieved',
            ));

        // Act
        final result = await referenceDataService.getCitiesByCountry(countryId);

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[0].name, equals('New York'));
      });
    });

    group('getGenders', () {
      test('should return list of genders on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {'id': 1, 'name': 'Male'},
            {'id': 2, 'name': 'Female'},
            {'id': 3, 'name': 'Non-binary'},
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Genders retrieved',
            ));

        // Act
        final result = await referenceDataService.getGenders();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(3));
        expect(result[0].name, equals('Male'));
        expect(result[1].name, equals('Female'));
        expect(result[2].name, equals('Non-binary'));
      });
    });

    group('getJobs', () {
      test('should return list of jobs on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {'id': 1, 'name': 'Software Engineer'},
            {'id': 2, 'name': 'Designer'},
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Jobs retrieved',
            ));

        // Act
        final result = await referenceDataService.getJobs();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
      });
    });

    group('getEducationLevels', () {
      test('should return list of education levels on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {'id': 1, 'name': 'High School'},
            {'id': 2, 'name': 'Bachelor\'s Degree'},
            {'id': 3, 'name': 'Master\'s Degree'},
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Education levels retrieved',
            ));

        // Act
        final result = await referenceDataService.getEducationLevels();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(3));
      });
    });

    group('getInterests', () {
      test('should return list of interests on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {'id': 1, 'name': 'Music'},
            {'id': 2, 'name': 'Sports'},
            {'id': 3, 'name': 'Travel'},
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Interests retrieved',
            ));

        // Act
        final result = await referenceDataService.getInterests();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(3));
      });
    });
  });
}

