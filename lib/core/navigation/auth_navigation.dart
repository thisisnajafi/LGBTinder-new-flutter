import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_router.dart';

/// Unauthenticated navigation helpers — keeps a predictable back stack.
///
/// Use [context.push] to open login/register/forgot from welcome or each other.
/// Use [context.go] only when completing auth (home, profile wizard, email verify).
abstract final class AuthNavigation {
  AuthNavigation._();

  /// Pop one level in the auth stack, or return to welcome if at root.
  static void popOrWelcome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.welcome);
  }

  /// Replace entire stack with home after successful authentication.
  static void completeToHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  /// Wrap auth screens so system back matches [popOrWelcome].
  static Widget backScope({
    required BuildContext context,
    required Widget child,
  }) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrWelcome(context);
      },
      child: child,
    );
  }
}
