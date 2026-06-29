import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
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

    final Color backgroundColor;
    final Color foregroundColor;
    final Color borderColor;
    final double elevation;

    if (widget.lightStyle) {
      backgroundColor = Colors.white;
      foregroundColor = const Color(0xFF1F1F1F);
      borderColor = const Color(0xFFDADCE0);
      elevation = 1;
    } else if (isDark) {
      backgroundColor = AppColors.surfaceDark;
      foregroundColor = AppColors.textPrimaryDark;
      borderColor = AppColors.borderMediumDark;
      elevation = 0;
    } else {
      backgroundColor = Colors.white;
      foregroundColor = const Color(0xFF1F1F1F);
      borderColor = AppColors.borderMediumLight;
      elevation = 0;
    }

    return Semantics(
      label: 'Continue with Google',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: backgroundColor,
          elevation: elevation,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          child: InkWell(
            onTap: _isLoading ? null : _handleGoogleSignIn,
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            foregroundColor,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _GoogleLogoMark(size: 24),
                        SizedBox(width: AppSpacing.spacingMD),
                        Text(
                          'Continue with Google',
                          style: AppTypography.button.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
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

class _GoogleLogoMark extends StatelessWidget {
  const _GoogleLogoMark({this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppIcons.googleLogo,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
