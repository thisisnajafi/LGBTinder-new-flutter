import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/api_providers.dart';
import '../../../routes/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_service_provider.dart';

/// Syncs session after profile completion and replaces the wizard stack with home.
Future<void> finishProfileOnboardingAndGoHome(
  WidgetRef ref,
  BuildContext context, {
  bool profileSubmissionComplete = false,
}) async {
  final authService = ref.read(authServiceProvider);

  try {
    final refreshed = await authService.checkToken();
    await authService.syncBootstrapSession(refreshed);
    await ref.read(authProvider.notifier).checkAuthStatus();
    if (refreshed.isComplete && context.mounted) {
      context.go(AppRoutes.home);
      return;
    }
  } catch (_) {
    // Fall through to local session repair when bootstrap check fails.
  }

  if (profileSubmissionComplete) {
    final tokenStorage = ref.read(tokenStorageServiceProvider);
    final session = await tokenStorage.getUserSession();
    final user = session?.user;
    if (user != null) {
      await tokenStorage.saveUserSession(
        user: user,
        profileCompleted: true,
        userState: 'ready_for_app',
      );
      await tokenStorage.clearProfileCompletionToken();
    }
    await ref.read(authProvider.notifier).checkAuthStatus();
  }

  if (context.mounted) {
    context.go(AppRoutes.home);
  }
}
