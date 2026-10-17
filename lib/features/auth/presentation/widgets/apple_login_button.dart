import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/theme/border_radius_constants.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_service_provider.dart';
import '../../utils/auth_navigation.dart';

/// Sign in with Apple button (iOS). Native Apple sheet + backend identity token check.
class AppleLoginButton extends ConsumerStatefulWidget {
  const AppleLoginButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.onBeforeAuth,
    this.getDeviceName,
    this.lightStyle = false,
  });

  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final Future<void> Function()? onBeforeAuth;
  final Future<String> Function()? getDeviceName;
  final bool lightStyle;

  @override
  ConsumerState<AppleLoginButton> createState() => _AppleLoginButtonState();
}

class _AppleLoginButtonState extends ConsumerState<AppleLoginButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = (isDark && !widget.lightStyle)
        ? SignInWithAppleButtonStyle.white
        : SignInWithAppleButtonStyle.black;

    return Semantics(
      label: 'Sign in with Apple',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: _isLoading
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: style == SignInWithAppleButtonStyle.black
                      ? Colors.black
                      : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                ),
                child: Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        style == SignInWithAppleButtonStyle.black
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              )
            : SignInWithAppleButton(
                text: 'Sign in with Apple',
                height: 56,
                style: style,
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                onPressed: _handleAppleSignIn,
              ),
      ),
    );
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (widget.onBeforeAuth != null) {
        await widget.onBeforeAuth!();
      }

      final appleAuth = ref.read(appleAuthServiceProvider);
      final authService = ref.read(authServiceProvider);

      final result = await appleAuth.signIn();
      if (result == null) {
        return; // cancelled
      }

      final deviceName = widget.getDeviceName != null
          ? await widget.getDeviceName!()
          : 'ios';

      final response = await authService.signInWithApple(
        identityToken: result.identityToken,
        rawNonce: result.rawNonce,
        givenName: result.givenName,
        familyName: result.familyName,
        authorizationCode: result.authorizationCode,
        deviceName: deviceName,
      );
      await appleAuth.clearPendingName(result.userIdentifier);

      final loginResponse = AuthNavigation.toLoginResponse(response);
      await ref.read(authProvider.notifier).login(loginResponse);

      if (!mounted) return;

      AuthNavigation.navigateAfterAuth(
        context,
        userState: response.userState,
        profileCompleted: response.profileCompleted,
        email: response.email,
        firstName: response.firstName,
        lastName: response.lastName,
      );

      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;

      final String message;
      if (e is ApiError) {
        message = e.message;
      } else if (e is StateError) {
        message = e.message;
      } else if (e is SignInWithAppleAuthorizationException) {
        message = e.code == AuthorizationErrorCode.notHandled ||
                e.code == AuthorizationErrorCode.unknown
            ? 'Sign in with Apple is unavailable. Check that you are signed in '
                'to iCloud and try again.'
            : 'Sign in with Apple failed. Please try again.';
      } else if (e is SignInWithAppleNotSupportedException) {
        message = 'Sign in with Apple is not supported on this device.';
      } else {
        message = 'Failed to sign in with Apple. Please try again.';
      }

      ErrorHandlerService.showErrorSnackBar(
        context,
        ApiError(message: message, code: 0),
      );
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
