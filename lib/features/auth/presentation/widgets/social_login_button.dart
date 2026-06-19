import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_service_provider.dart';
import '../../utils/auth_navigation.dart';

typedef GoogleSignInCallback = Future<void> Function();

/// Production Google sign-in button (native SDK + backend ID token verification).
class SocialLoginButton extends ConsumerStatefulWidget {
  const SocialLoginButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.onBeforeAuth,
    this.getDeviceName,
    this.lightStyle = false,
  });

  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final GoogleSignInCallback? onBeforeAuth;
  final Future<String> Function()? getDeviceName;
  final bool lightStyle;

  @override
  ConsumerState<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends ConsumerState<SocialLoginButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = widget.lightStyle
        ? Colors.white
        : (isDark ? AppColors.surfaceDark : Colors.white);
    final foregroundColor =
        widget.lightStyle ? Colors.black87 : AppColors.textPrimaryLight;
    final borderColor = widget.lightStyle
        ? Colors.white.withValues(alpha: 0.55)
        : (isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: widget.lightStyle ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              widget.lightStyle ? AppRadius.radiusRound : AppRadius.radiusLG,
            ),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleMark(),
                  SizedBox(width: AppSpacing.spacingMD),
                  Text(
                    'Continue with Google',
                    style: AppTypography.labelMedium.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      if (widget.onBeforeAuth != null) {
        await widget.onBeforeAuth!();
      }

      final googleAuth = ref.read(googleAuthServiceProvider);
      final authService = ref.read(authServiceProvider);

      final idToken = await googleAuth.signIn();
      if (idToken == null) {
        return;
      }

      final deviceName = widget.getDeviceName != null
          ? await widget.getDeviceName!()
          : 'mobile';

      final response = await authService.signInWithGoogle(
        idToken: idToken,
        deviceName: deviceName,
      );

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

      final message = e is ApiError
          ? e.message
          : e is StateError
              ? e.message
              : 'Failed to sign in with Google. Please try again.';

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

class _GoogleMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
