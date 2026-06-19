import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_router.dart';
import '../data/models/login_response.dart';
import '../data/models/social_auth_response.dart';

/// Shared post-authentication navigation for email and Google flows.
class AuthNavigation {
  AuthNavigation._();

  static void navigateAfterAuth(
    BuildContext context, {
    required String? userState,
    required bool profileCompleted,
    String? email,
    String? firstName,
    String? lastName,
    bool showSuccessSnackBar = true,
  }) {
    if (userState == 'email_verification_required') {
      if (email != null && email.isNotEmpty) {
        final target = Uri(
          path: AppRoutes.emailVerification,
          queryParameters: {
            'email': email,
            'isNewUser': 'false',
          },
        ).toString();
        context.go(target);
      } else {
        context.go(AppRoutes.emailVerification);
      }
      return;
    }

    if (userState == 'ready_for_app' || profileCompleted) {
      if (showSuccessSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Signed in successfully'),
            backgroundColor: AppColors.onlineGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      context.go(AppRoutes.home);
      return;
    }

    if (userState == 'profile_completion_required' || !profileCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile to continue'),
          backgroundColor: AppColors.accentPurple,
          duration: Duration(seconds: 2),
        ),
      );

      final trimmedFirst = firstName?.trim();
      if (trimmedFirst != null && trimmedFirst.isNotEmpty) {
        final params = <String, String>{'firstName': trimmedFirst};
        final trimmedLast = lastName?.trim();
        if (trimmedLast != null && trimmedLast.isNotEmpty) {
          params['lastName'] = trimmedLast;
        }
        context.go(
          Uri(path: AppRoutes.profileWizard, queryParameters: params).toString(),
        );
      } else {
        context.go(AppRoutes.profileWizard);
      }
    }
  }

  static LoginResponse toLoginResponse(SocialAuthResponse response) {
    return LoginResponse(
      token: response.token,
      tokenType: response.tokenType,
      profileCompleted: response.profileCompleted,
      needsProfileCompletion: response.needsProfileCompletion,
      userState: response.userState,
      firstName: response.firstName,
      user: response.userId != null && response.email != null
          ? UserData(
              id: response.userId!,
              firstName: response.firstName ?? 'User',
              lastName: response.lastName ?? '',
              email: response.email!,
            )
          : null,
    );
  }
}
