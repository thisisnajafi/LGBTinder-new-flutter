import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/data/models/social_auth_response.dart';
import 'package:lgbtindernew/features/auth/utils/auth_navigation.dart';

void main() {
  group('AuthNavigation.toLoginResponse', () {
    test('copies Google Sign-In fields into LoginResponse', () {
      final social = SocialAuthResponse(
        status: true,
        message: 'ok',
        userId: 42,
        email: 'newuser@example.com',
        token: 'sanctum-token',
        tokenType: 'Bearer',
        profileCompleted: false,
        needsProfileCompletion: true,
        userState: 'profile_completion_required',
        firstName: 'New',
        lastName: 'User',
        isNewUser: true,
      );

      final login = AuthNavigation.toLoginResponse(social);

      expect(login.token, 'sanctum-token');
      expect(login.tokenType, 'Bearer');
      expect(login.profileCompleted, isFalse);
      expect(login.needsProfileCompletion, isTrue);
      expect(login.userState, 'profile_completion_required');
      expect(login.firstName, 'New');
      expect(login.user?.id, 42);
      expect(login.user?.email, 'newuser@example.com');
      expect(login.user?.firstName, 'New');
      expect(login.user?.lastName, 'User');
    });
  });
}
