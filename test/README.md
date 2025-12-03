# Testing Guide - LGBTinder Flutter App

This directory contains all tests for the LGBTinder Flutter application.

## Test Structure

```
test/
├── helpers/
│   └── test_helpers.dart          # Test utilities and helpers
├── unit/
│   └── services/
│       ├── auth_service_test.dart  # AuthService unit tests
│       └── user_service_test.dart  # UserService unit tests
├── widget/
│   └── screens/
│       └── login_screen_test.dart # LoginScreen widget tests
├── integration/
│   └── auth_flow_test.dart        # Authentication flow integration tests
├── widget_test.dart                # Basic smoke test
└── README.md                       # This file
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/unit/services/auth_service_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Generate mocks (for mockito)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Test Types

### Unit Tests
Test individual services, models, and utilities in isolation.
- Location: `test/unit/`
- Example: `auth_service_test.dart`

### Widget Tests
Test individual widgets and screens.
- Location: `test/widget/`
- Example: `login_screen_test.dart`

### Integration Tests
Test complete user flows and interactions.
- Location: `test/integration/`
- Example: `auth_flow_test.dart`

## Writing Tests

### Unit Test Example
```dart
test('should return UserInfo on successful API call', () async {
  // Arrange
  when(mockApiService.get(any)).thenAnswer((_) async => successResponse);
  
  // Act
  final result = await userService.getUserInfo();
  
  // Assert
  expect(result, isNotNull);
  expect(result.email, equals('test@example.com'));
});
```

### Widget Test Example
```dart
testWidgets('should display email field', (WidgetTester tester) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: createTestContainer(),
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  
  expect(find.byType(TextField), findsOneWidget);
});
```

## Mocking

We use `mockito` and `mocktail` for mocking dependencies.

### Generate Mocks
Run `flutter pub run build_runner build` after adding `@GenerateMocks` annotations.

### Example Mock Setup
```dart
@GenerateMocks([ApiService, TokenStorageService])
void main() {
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
  });
}
```

## Test Coverage Goals

- **Unit Tests**: 80%+ coverage for services
- **Widget Tests**: 70%+ coverage for critical screens
- **Integration Tests**: All major user flows

## Best Practices

1. **Arrange-Act-Assert**: Structure tests clearly
2. **Test Isolation**: Each test should be independent
3. **Mock External Dependencies**: Don't make real API calls in tests
4. **Test Edge Cases**: Include error scenarios
5. **Keep Tests Fast**: Unit tests should run quickly
6. **Descriptive Names**: Test names should describe what they test

## Continuous Integration

Tests should run automatically on:
- Pull requests
- Commits to main branch
- Before deployment

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)

