import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/profile/providers/profile_wizard_provider.dart';

void main() {
  group('ProfileWizardNotifier', () {
    test('resolveResumeStep is 0 until a photo exists', () {
      final notifier = ProfileWizardNotifier();
      expect(notifier.resolveResumeStep(), 0);
      notifier.setPrimaryPhoto(File('preview.jpg'));
      expect(notifier.resolveResumeStep(), 1);
    });

    test('setCountry clears city', () {
      final notifier = ProfileWizardNotifier();
      notifier.setCity(10);
      notifier.setCountry(countryId: 2);
      expect(notifier.state.countryId, 2);
      expect(notifier.state.cityId, isNull);
    });

    test('seedCompleteForTests lands on the review resume step', () {
      final notifier = ProfileWizardNotifier();
      notifier.seedCompleteForTests(
        photo: File('preview.jpg'),
        name: 'Alex User',
        phoneNumber: '5551234567',
        countryCode: '+1',
        bio: 'Bio text for tests',
      );
      expect(notifier.state.hasProfilePhoto, isTrue);
      expect(notifier.state.cityId, 10);
      expect(notifier.resolveResumeStep(), 6);
    });
  });
}
