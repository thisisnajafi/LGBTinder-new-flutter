// Screen: EmailVerificationScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/auth_page_scaffold.dart';
import '../../core/responsive/responsive.dart';
import '../../features/auth/data/models/verify_email_request.dart';
import '../../features/auth/presentation/widgets/email_verification_form.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../routes/app_router.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../widgets/buttons/gradient_button.dart';

/// Email verification screen - Email verification flow with 6-digit code
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isNewUser; // true for registration, false for existing user
  final String? firstName;
  final String? lastName;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.isNewUser = true,
    this.firstName,
    this.lastName,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _isVerifying = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    if (widget.email.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is missing. Please restart verification.'),
          ),
        );
        context.go(AppRoutes.welcome);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _isVerifying.dispose();
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _getCode();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code')),
      );
      return;
    }

    _isVerifying.value = true;

    try {
      final authService = ref.read(authServiceProvider);

      final request = VerifyEmailRequest(
        email: widget.email,
        code: code,
      );

      final response = await authService.verifyEmail(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email verified successfully!'),
            backgroundColor: AppColors.onlineGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        if (response.profileCompleted) {
          context.go(AppRoutes.home);
        } else {
          final params = <String, String>{};
          final firstName = widget.firstName?.trim();
          final lastName = widget.lastName?.trim();
          if (firstName != null && firstName.isNotEmpty) {
            params['firstName'] = firstName;
          }
          if (lastName != null && lastName.isNotEmpty) {
            params['lastName'] = lastName;
          }
          context.go(
            Uri(
              path: AppRoutes.profileWizard,
              queryParameters: params.isEmpty ? null : params,
            ).toString(),
          );
        }
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Verification failed',
        );
        for (final controller in _codeControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Verification failed',
        );
        for (final controller in _codeControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        _isVerifying.value = false;
      }
    }
  }

  Future<bool> _resendCode() async {
    try {
      final authService = ref.read(authServiceProvider);
      if (widget.isNewUser) {
        await authService.resendVerificationCode(widget.email);
      } else {
        await authService.requestVerificationCodeForExistingUser(widget.email);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Verification code sent! Please check your email.',
            ),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
      return true;
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to resend code',
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to resend code',
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AuthPageScaffold(
      title: 'Verify Email',
      subtitle: 'Check your inbox',
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(widget.isNewUser ? AppRoutes.register : AppRoutes.login);
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.spacingXXL),
            Center(
              child: AppSvgIcon(
                assetPath: AppIcons.message,
                size: 80,
                color: AppColors.accentViolet,
              ),
            ),
            SizedBox(height: AppSpacing.spacingXL),
            Text(
              'Verify Your Email',
              style: AppTypography.h1.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              "We've sent a 6-digit verification code to",
              style: AppTypography.body.copyWith(color: secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingXS),
            AppText(
              widget.email,
              style: AppTypography.body.copyWith(
                color: AppColors.accentPurple,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            SizedBox(height: AppSpacing.spacingXXL),
            EmailOtpFields(
              controllers: _codeControllers,
              focusNodes: _focusNodes,
              onChanged: _onCodeChanged,
            ),
            SizedBox(height: AppSpacing.spacingXL),
            ValueListenableBuilder<bool>(
              valueListenable: _isVerifying,
              builder: (context, verifying, _) {
                return GradientButton(
                  text: verifying ? 'Verifying...' : 'Verify Email',
                  onPressed: verifying ? null : _verifyCode,
                  isLoading: verifying,
                  isFullWidth: true,
                  iconPath: AppIcons.shieldTick,
                );
              },
            ),
            SizedBox(height: AppSpacing.spacingLG),
            EmailResendRow(onResend: _resendCode),
            SizedBox(height: AppSpacing.spacingXL),
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.info,
                    color: AppColors.accentViolet,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: Text(
                      "The code will expire in 5 minutes. Check your spam folder if you don't see the email.",
                      style: AppTypography.caption.copyWith(color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
