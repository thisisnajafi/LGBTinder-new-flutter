import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/data/models/social_auth_response.dart';

void main() {
  group('SocialAuthResponse.fromJson', () {
    test('parses backend Google Sign-In success payload for a new user', () {
      final response = SocialAuthResponse.fromJson({
        'status': 'success',
        'message': 'Account created successfully with Google',
        'data': {
          'user': {
            'id': 42,
            'first_name': 'New',
            'last_name': 'User',
            'name': 'New User',
            'email': 'newuser@example.com',
            'email_verified': true,
            'profile_complete': false,
            'profile_completed': false,
            'onboarding_completed': false,
            'has_profile_picture': false,
          },
          'user_id': 42,
          'email': 'newuser@example.com',
          'first_name': 'New',
          'token': 'sanctum-token',
          'token_type': 'Bearer',
          'is_new_user': true,
          'account_linked': false,
          'user_state': 'profile_completion_required',
          'profile_completed': false,
          'needs_profile_completion': true,
          'next_step': 'complete_profile',
        },
      });

      expect(response.status, isTrue);
      expect(response.userId, 42);
      expect(response.email, 'newuser@example.com');
      expect(response.firstName, 'New');
      expect(response.token, 'sanctum-token');
      expect(response.tokenType, 'Bearer');
      expect(response.isNewUser, isTrue);
      expect(response.accountLinked, isFalse);
      expect(response.profileCompleted, isFalse);
      expect(response.needsProfileCompletion, isTrue);
      expect(response.userState, 'profile_completion_required');
    });

    test('parses backend payload for an existing linked user', () {
      final response = SocialAuthResponse.fromJson({
        'status': 'success',
        'message': 'Successfully logged in with Google',
        'data': {
          'user': {
            'id': 7,
            'first_name': 'Existing',
            'last_name': 'User',
            'email': 'existing@example.com',
            'profile_completed': true,
            'profile_complete': true,
          },
          'user_id': 7,
          'email': 'existing@example.com',
          'token': 'permanent-token',
          'token_type': 'Bearer',
          'is_new_user': false,
          'account_linked': false,
          'user_state': 'ready_for_app',
          'profile_completed': true,
          'needs_profile_completion': false,
        },
      });

      expect(response.status, isTrue);
      expect(response.isNewUser, isFalse);
      expect(response.profileCompleted, isTrue);
      expect(response.needsProfileCompletion, isFalse);
      expect(response.userState, 'ready_for_app');
    });

    test('maps account_linked when Google is attached to an existing email', () {
      final response = SocialAuthResponse.fromJson({
        'status': 'success',
        'message': 'Google account linked successfully',
        'data': {
          'user_id': 9,
          'email': 'linked@example.com',
          'token': 'linked-token',
          'is_new_user': false,
          'account_linked': true,
          'user_state': 'profile_completion_required',
          'profile_completed': false,
          'needs_profile_completion': true,
        },
      });

      expect(response.accountLinked, isTrue);
      expect(response.isNewUser, isFalse);
      expect(response.userId, 9);
    });
  });
}
