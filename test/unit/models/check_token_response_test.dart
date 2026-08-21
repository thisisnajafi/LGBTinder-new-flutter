import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/data/models/check_token_response.dart';
import 'package:lgbtindernew/features/auth/data/models/login_response.dart';

void main() {
  group('CheckTokenResponse.fromJson', () {
    test('treats wizard-done column as complete even if checklist fails', () {
      final response = CheckTokenResponse.fromJson({
        'user_state': 'profile_completion_required',
        'is_complete': false,
        'profile_completed': false,
        'needs_profile_completion': true,
        'profile_completion_status': {
          'is_complete': false,
          'profile_completed': true,
          'needs_profile_completion': true,
          'missing_fields': ['avatar'],
        },
        'user': {
          'id': 1,
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'email': 'ada@example.com',
        },
      });

      expect(response.isComplete, isTrue);
      expect(response.needsProfileCompletion, isFalse);
      expect(response.userState, 'ready_for_app');
      expect(response.user?.email, 'ada@example.com');
    });

    test('keeps incomplete users in the wizard', () {
      final response = CheckTokenResponse.fromJson({
        'user_state': 'profile_completion_required',
        'is_complete': false,
        'profile_completed': false,
        'needs_profile_completion': true,
        'profile_completion_status': {
          'is_complete': false,
          'profile_completed': false,
        },
      });

      expect(response.isComplete, isFalse);
      expect(response.needsProfileCompletion, isTrue);
      expect(response.userState, 'profile_completion_required');
    });
  });

  group('LoginResponse.fromJson', () {
    test('does not prefer a failed checklist over wizard-done column', () {
      final response = LoginResponse.fromJson({
        'user_state': 'profile_completion_required',
        'is_complete': false,
        'profile_completed': true,
        'needs_profile_completion': true,
        'profile_completion_status': {
          'is_complete': false,
          'profile_completed': true,
        },
        'token': 'full-access-token',
        'user': {
          'id': 1,
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'email': 'ada@example.com',
        },
      });

      expect(response.profileCompleted, isTrue);
      expect(response.needsProfileCompletion, isFalse);
      expect(response.userState, 'ready_for_app');
    });
  });
}
