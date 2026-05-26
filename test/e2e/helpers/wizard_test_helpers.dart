import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/data/models/complete_registration_response.dart';
import 'package:lgbtindernew/features/auth/data/services/auth_service.dart';
import 'package:lgbtindernew/features/auth/providers/auth_service_provider.dart';
import 'package:lgbtindernew/features/profile/data/models/user_image.dart';
import 'package:lgbtindernew/features/profile/data/services/image_service.dart';
import 'package:lgbtindernew/features/profile/data/services/profile_service.dart';
import 'package:lgbtindernew/features/profile/providers/profile_providers.dart';
import 'package:lgbtindernew/features/reference_data/data/models/reference_item.dart';
import 'package:lgbtindernew/features/reference_data/data/services/reference_data_service.dart';
import 'package:lgbtindernew/features/reference_data/providers/reference_data_providers.dart';
import 'package:lgbtindernew/pages/profile_wizard_page.dart';
import 'package:lgbtindernew/widgets/buttons/gradient_button.dart';
import 'package:mocktail/mocktail.dart';

import 'app_bootstrap.dart';
import 'mock_services.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockImageService extends Mock implements ImageService {}

class MockReferenceDataService extends Mock implements ReferenceDataService {}

List<ReferenceItem> get sampleCountries => [
      ReferenceItem(id: 1, title: 'United States', phoneCode: '+1'),
    ];

List<ReferenceItem> get sampleCities => [
      ReferenceItem(id: 10, title: 'New York'),
    ];

List<ReferenceItem> get sampleGenders => [
      ReferenceItem(id: 2, title: 'Man'),
    ];

List<ReferenceItem> get sampleJobs => [
      ReferenceItem(id: 3, title: 'Engineer'),
    ];

List<ReferenceItem> get sampleEducations => [
      ReferenceItem(id: 4, title: 'Bachelor'),
    ];

List<ReferenceItem> get sampleLanguages => [
      ReferenceItem(id: 5, title: 'English'),
    ];

List<ReferenceItem> get sampleInterests => [
      ReferenceItem(id: 6, title: 'Music'),
      ReferenceItem(id: 7, title: 'Travel'),
    ];

List<ReferenceItem> get sampleMusic => [
      ReferenceItem(id: 8, title: 'Pop'),
    ];

List<ReferenceItem> get sampleRelationGoals => [
      ReferenceItem(id: 9, title: 'Long-term'),
    ];

MockReferenceDataService createMockReferenceDataService() {
  final service = MockReferenceDataService();
  when(() => service.getCountries()).thenAnswer((_) async => sampleCountries);
  when(() => service.getCitiesByCountry(any())).thenAnswer((_) async => sampleCities);
  when(() => service.getGenders()).thenAnswer((_) async => sampleGenders);
  when(() => service.getPreferredGenders()).thenAnswer((_) async => sampleGenders);
  when(() => service.getJobs()).thenAnswer((_) async => sampleJobs);
  when(() => service.getEducationLevels()).thenAnswer((_) async => sampleEducations);
  when(() => service.getLanguages()).thenAnswer((_) async => sampleLanguages);
  when(() => service.getInterests()).thenAnswer((_) async => sampleInterests);
  when(() => service.getMusicGenres()).thenAnswer((_) async => sampleMusic);
  when(() => service.getRelationshipGoals()).thenAnswer((_) async => sampleRelationGoals);
  return service;
}

List<Override> wizardReferenceOverrides() {
  return [
    referenceDataServiceProvider.overrideWithValue(createMockReferenceDataService()),
  ];
}

List<Override> wizardServiceOverrides({
  MockProfileService? profile,
  MockImageService? images,
  MockAuthService? auth,
}) {
  final profileService = profile ?? MockProfileService();
  final imageService = images ?? MockImageService();
  final authService = auth ?? MockAuthService();

  when(() => profileService.getMyProfile()).thenThrow(Exception('no profile in test'));
  when(
    () => imageService.uploadImage(any(), type: any(named: 'type')),
  ).thenAnswer(
    (_) async => UserImage(
      id: 1,
      userId: 1,
      path: '/test/photo.jpg',
      type: 'primary',
      order: 0,
      isPrimary: true,
    ),
  );
  when(() => authService.completeRegistration(any())).thenAnswer(
    (_) async => CompleteRegistrationResponse(
      token: 'full-auth-token',
      profileCompleted: true,
    ),
  );

  return [
    profileServiceProvider.overrideWithValue(profileService),
    imageServiceProvider.overrideWithValue(imageService),
    authServiceProvider.overrideWithValue(authService),
    ...wizardReferenceOverrides(),
  ];
}

File? _wizardPhotoCache;

/// Local fixture file — avoids [Directory.systemTemp.createTemp] hanging in widget tests on Windows.
File wizardPhotoFile() {
  if (_wizardPhotoCache != null) return _wizardPhotoCache!;
  final file = File('test/e2e/.tmp_wizard_photo.jpg');
  if (!file.existsSync()) {
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
  }
  _wizardPhotoCache = file;
  return file;
}

dynamic _wizardState(WidgetTester tester) =>
    tester.state(find.byType(ProfileWizardPage));

int wizardCurrentStep(WidgetTester tester) =>
    (_wizardState(tester) as dynamic).testCurrentStep as int;

Future<void> pumpProfileWizard(
  WidgetTester tester, {
  List<Override> overrides = const [],
  String? initialFirstName,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...wizardServiceOverrides(),
        ...overrides,
      ],
      child: MaterialApp(
        home: ProfileWizardPage(initialFirstName: initialFirstName),
      ),
    ),
  );
  await e2ePumpFrames(tester, frames: 8);
}

Future<void> seedWizardPhoto(WidgetTester tester) async {
  (_wizardState(tester) as dynamic).testSeedPrimaryPhoto(wizardPhotoFile());
  await tester.pump();
}

Future<void> jumpToWizardStep(WidgetTester tester, int step) async {
  (_wizardState(tester) as dynamic).testJumpToStep(step);
  await tester.pump();
}

Future<void> tapWizardNext(WidgetTester tester) async {
  await tester.tap(find.byType(GradientButton));
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> tapWizardBack(WidgetTester tester) async {
  await tester.tap(find.text('Back'));
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> tapWizardComplete(WidgetTester tester) async {
  await tester.tap(find.text('Complete'));
  await tester.pump();
  await e2ePumpFrames(tester, frames: 10);
}

void seedWizardStep1Phone(WidgetTester tester) {
  (_wizardState(tester) as dynamic).testSeedStep1Phone();
}

void seedCompleteWizardState(WidgetTester tester, File photo) {
  (_wizardState(tester) as dynamic).testSeedCompleteState(photo);
}
