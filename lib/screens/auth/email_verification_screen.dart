// Screen: EmailVerificationScreen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../features/auth/data/models/verify_email_request.dart';
import '../../features/auth/data/models/register_request.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import 'package:go_router/go_router.dart';
import '../../pages/profile_wizard_page.dart';

/// Email verification screen - Email verification flow with 6-digit code
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isNewUser; // true for registration, false for existing user

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    this.isNewUser = true,
  }) : super(key: key);

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown(120); // 2 minutes initial countdown
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    setState(() {
      _resendCountdown = seconds;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field filled, verify automatically
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
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

    setState(() {
      _isVerifying = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      
      final request = VerifyEmailRequest(
        email: widget.email,
        code: code,
      );

      final response = await authService.verifyEmail(request);

      if (mounted) {
        // Save token if provided (for profile completion)
        if (response.token != null) {
          // Token is already saved in auth service, but we can verify here
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email verified successfully!'),
            backgroundColor: AppColors.onlineGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate based on profile completion status
        if (mounted) {
          // Check if profile is completed
          if (response.profileCompleted) {
            // Profile is completed, go to home
            context.go('/home');
          } else {
            // Profile not completed, go to profile wizard
            context.go('/profile-wizard');
          }
        }
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Verification failed',
        );
        // Clear code on error
        for (var controller in _codeControllers) {
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
        // Clear code on error
        for (var controller in _codeControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // Use the proper resend verification endpoint
      if (widget.isNewUser == true) {
        // For new user registration, use resend-verification
        await authService.resendVerificationCode(widget.email);
      } else {
        // For existing user verification, use resend-verification-existing
        await authService.requestVerificationCodeForExistingUser(widget.email);
      }

      if (mounted) {
        _startResendCountdown(120); // 2 minutes countdown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification code sent! Please check your email.'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to resend code',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to resend code',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Verify Email',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.spacingXXL),
              // Icon
              Icon(
                Icons.email_outlined,
                size: 80,
                color: AppColors.accentPurple,
              ),
              SizedBox(height: AppSpacing.spacingXL),
              // Title
              Text(
                'Verify Your Email',
                style: AppTypography.h1.copyWith(
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              // Description
              Text(
                'We\'ve sent a 6-digit verification code to',
                style: AppTypography.body.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacingXS),
              Text(
                widget.email,
                style: AppTypography.body.copyWith(
                  color: AppColors.accentPurple,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacingXXL),
              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return _buildCodeField(
                    index: index,
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  );
                }),
              ),
              SizedBox(height: AppSpacing.spacingXL),
              // Verify button
              GradientButton(
                text: _isVerifying ? 'Verifying...' : 'Verify Email',
                onPressed: _isVerifying ? null : _verifyCode,
                isLoading: _isVerifying,
                isFullWidth: true,
                icon: Icons.verified,
              ),
              SizedBox(height: AppSpacing.spacingLG),
              // Resend code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code? ',
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_formatCountdown(_resendCountdown)}',
                      style: AppTypography.body.copyWith(
                        color: secondaryTextColor,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _isResending ? null : _resendCode,
                      child: Text(
                        _isResending ? 'Sending...' : 'Resend Code',
                        style: AppTypography.button.copyWith(
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.spacingXL),
              // Help text
              Container(
                padding: EdgeInsets.all(AppSpacing.spacingMD),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.accentPurple,
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.spacingMD),
                    Expanded(
                      child: Text(
                        'The code will expire in 5 minutes. Check your spam folder if you don\'t see the email.',
                        style: AppTypography.caption.copyWith(
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField({
    required int index,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.accentPurple
              : borderColor,
          width: focusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTypography.h1.copyWith(
          color: textColor,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onCodeChanged(index, value),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
