/// Unit tests for AuthService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/auth/data/services/auth_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:lgbtindernew/features/auth/data/models/register_request.dart';
import 'package:lgbtindernew/features/auth/data/models/login_request.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([
  ApiService,
  TokenStorageService,
  DioClient,
])
void main() {
  late AuthService authService;
  late MockApiService mockApiService;
  late MockTokenStorageService mockTokenStorage;
  late MockDioClient mockDioClient;

  setUp(() {
    mockApiService = MockApiService();
    mockTokenStorage = MockTokenStorageService();
    mockDioClient = MockDioClient();
    authService = AuthService(
      mockApiService,
      mockTokenStorage,
      mockDioClient,
    );
  });

  group('AuthService', () {
    group('register', () {
      test('should return RegisterResponse on successful registration', () async {
        // Arrange
        final request = RegisterRequest(
          email: 'test@example.com',
          password: 'password123',
          firstName: 'Test',
          lastName: 'User',
        );

        final responseData = {
          'status': true,
          'message': 'Registration successful',
          'data': {
            'user': {
              'id': 1,
              'email': 'test@example.com',
              'first_name': 'Test',
              'last_name': 'User',
            },
            'token': 'test_token',
          },
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Registration successful',
        ));

        // Act
        final result = await authService.register(request);

        // Assert
        expect(result, isNotNull);
        expect(result.user.email, equals('test@example.com'));
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed registration', () async {
        // Arrange
        final request = RegisterRequest(
          email: 'test@example.com',
          password: 'password123',
          firstName: 'Test',
          lastName: 'User',
        );

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Registration failed',
        ));

        // Act & Assert
        expect(
          () => authService.register(request),
          throwsException,
        );
      });
    });

    group('login', () {
      test('should return LoginResponse and save token on successful login', () async {
        // Arrange
        final request = LoginRequest(
          email: 'test@example.com',
          password: 'password123',
        );

        final responseData = {
          'status': true,
          'message': 'Login successful',
          'data': {
            'user': {
              'id': 1,
              'email': 'test@example.com',
              'first_name': 'Test',
              'last_name': 'User',
            },
            'token': 'test_token',
          },
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Login successful',
        ));

        when(mockTokenStorage.saveAuthToken(any)).thenAnswer((_) async => {});

        // Act
        final result = await authService.login(request);

        // Assert
        expect(result, isNotNull);
        expect(result.user.email, equals('test@example.com'));
        verify(mockTokenStorage.saveAuthToken('test_token')).called(1);
      });

      test('should throw exception on failed login', () async {
        // Arrange
        final request = LoginRequest(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Invalid credentials',
        ));

        // Act & Assert
        expect(
          () => authService.login(request),
          throwsException,
        );
      });
    });
  });
}

