import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../../../shared/models/api_error.dart';
import '../../providers/auth_service_provider.dart';

/// Social login button widget - supports Google OAuth
class SocialLoginButton extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const SocialLoginButton({
    Key? key,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends ConsumerState<SocialLoginButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
            side: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black87 : Colors.black87,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google logo placeholder (you can replace with actual Google logo)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Text(
                    'Continue with Google',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
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
      // Get Google OAuth URL from backend
      final authService = ref.read(authServiceProvider);
      final authUrlResponse = await authService.getGoogleAuthUrl();

      if (authUrlResponse.isSuccess && authUrlResponse.data != null) {
        final authUrl = authUrlResponse.data!['authorization_url'] as String;
        final state = authUrlResponse.data!['state'] as String;

        // Store state securely for callback validation
        const storage = FlutterSecureStorage();
        await storage.write(key: 'oauth_state', value: state);

        // Launch URL in external browser
        final Uri url = Uri.parse(authUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );

          // Note: For mobile apps, you would typically handle the callback
          // through deep linking or a custom URL scheme
          // The callback would then call the social login use case

          widget.onSuccess?.call();
        } else {
          throw Exception('Could not launch Google OAuth URL');
        }
      } else {
        throw Exception(authUrlResponse.message);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          ApiError(
            message: 'Failed to sign in with Google: ${e.toString()}',
            code: 0,
          ),
        );
      }
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
