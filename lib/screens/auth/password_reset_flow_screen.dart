// Screen: PasswordResetFlowScreen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';
import '../../core/utils/app_icons.dart';

/// Password reset flow screen - Multi-step password reset with OTP
class PasswordResetFlowScreen extends ConsumerStatefulWidget {
  const PasswordResetFlowScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PasswordResetFlowScreen> createState() => _PasswordResetFlowScreenState();
}

class _PasswordResetFlowScreenState extends ConsumerState<PasswordResetFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0: Email, 1: OTP, 2: New Password

  // Step 1: Email
  final _emailController = TextEditingController();
  bool _isSendingOtp = false;

  // Step 2: OTP
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifyingOtp = false;
  bool _isResendingOtp = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  String? _resetToken;

  // Step 3: New Password
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isResettingPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _pageController.dispose();
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

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      // TODO: Send OTP via API
      // POST /api/auth/send-password-reset-otp
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _startResendCountdown(120); // 2 minutes
        _nextStep();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _getOtpCode();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code')),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      // TODO: Verify OTP via API
      // POST /api/auth/verify-password-reset-otp
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _resetToken = 'token_from_api'; // TODO: Get from API response
        });
        _nextStep();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid or expired code: $e')),
        );
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResendingOtp = true;
    });

    try {
      // TODO: Resend OTP via API
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _startResendCountdown(120);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingOtp = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() {
      _isResettingPassword = true;
    });

    try {
      // TODO: Reset password via API
      // POST /api/auth/reset-password
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Password Reset',
          message: 'Your password has been reset successfully! You can now login with your new password.',
          iconPath: AppIcons.checkCircle,
          iconColor: AppColors.onlineGreen,
        ).then((_) {
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        title: 'Reset Password',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Row(
              children: [
                _buildProgressStep(0, 'Email', textColor, secondaryTextColor),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep > 0
                        ? AppColors.accentPurple
                        : borderColor,
                  ),
                ),
                _buildProgressStep(1, 'Verify', textColor, secondaryTextColor),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep > 1
                        ? AppColors.accentPurple
                        : borderColor,
                  ),
                ),
                _buildProgressStep(2, 'Reset', textColor, secondaryTextColor),
              ],
            ),
          ),
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildEmailStep(
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                _buildOtpStep(
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                _buildPasswordStep(
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, Color textColor, Color secondaryTextColor) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? AppColors.accentPurple
                : secondaryTextColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? AppSvgIcon(
                  assetPath: AppIcons.check,
                  size: 20,
                  color: Colors.white,
                )
              : Center(
                  child: Text(
                    '${step + 1}',
                    style: AppTypography.body.copyWith(
                      color: isActive ? Colors.white : secondaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        SizedBox(height: AppSpacing.spacingXS),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isActive || isCompleted ? textColor : secondaryTextColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep({
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.spacingXXL),
          AppSvgIcon(
            assetPath: AppIcons.lockReset,
            size: 80,
            color: AppColors.accentPurple,
          ),
          SizedBox(height: AppSpacing.spacingXL),
          Text(
            'Reset Your Password',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Enter your email address and we\'ll send you a verification code',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: AppSvgIcon(
                assetPath: AppIcons.emailOutlined,
                size: 20,
                color: secondaryTextColor,
              ),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            style: AppTypography.body.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          GradientButton(
            text: _isSendingOtp ? 'Sending...' : 'Send Verification Code',
            onPressed: _isSendingOtp ? null : _sendOtp,
            isLoading: _isSendingOtp,
            isFullWidth: true,
            iconPath: AppIcons.sendIcon,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep({
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.spacingXXL),
          Icon(
            Icons.verified_user,
            size: 80,
            color: AppColors.accentPurple,
          ),
          SizedBox(height: AppSpacing.spacingXL),
          Text(
            'Enter Verification Code',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'We\'ve sent a 6-digit code to ${_emailController.text}',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return _buildOtpField(
                index: index,
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textColor: textColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              );
            }),
          ),
          SizedBox(height: AppSpacing.spacingXL),
          GradientButton(
            text: _isVerifyingOtp ? 'Verifying...' : 'Verify Code',
            onPressed: _isVerifyingOtp ? null : _verifyOtp,
            isLoading: _isVerifyingOtp,
            isFullWidth: true,
            icon: Icons.verified,
          ),
          SizedBox(height: AppSpacing.spacingLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Didn\'t receive the code? ',
                style: AppTypography.body.copyWith(color: secondaryTextColor),
              ),
              if (_resendCountdown > 0)
                Text(
                  'Resend in ${_formatCountdown(_resendCountdown)}',
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                )
              else
                TextButton(
                  onPressed: _isResendingOtp ? null : _resendOtp,
                  child: Text(
                    _isResendingOtp ? 'Sending...' : 'Resend Code',
                    style: AppTypography.button.copyWith(
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep({
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.spacingXXL),
          AppSvgIcon(
            assetPath: AppIcons.lockOutline,
            size: 80,
            color: AppColors.accentPurple,
          ),
          SizedBox(height: AppSpacing.spacingXL),
          Text(
            'Create New Password',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Enter your new password. Make sure it\'s strong and secure.',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: AppSvgIcon(
                assetPath: AppIcons.lock,
                size: 20,
                color: secondaryTextColor,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: secondaryTextColor,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            style: AppTypography.body.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: AppSvgIcon(
                assetPath: AppIcons.lockOutline,
                size: 20,
                color: secondaryTextColor,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: secondaryTextColor,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            style: AppTypography.body.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: AppColors.accentPurple.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements:',
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                _buildRequirement('At least 8 characters', textColor),
                _buildRequirement('One uppercase letter', textColor),
                _buildRequirement('One lowercase letter', textColor),
                _buildRequirement('One number', textColor),
                _buildRequirement('One special character', textColor),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          GradientButton(
            text: _isResettingPassword ? 'Resetting...' : 'Reset Password',
            onPressed: _isResettingPassword ? null : _resetPassword,
            isLoading: _isResettingPassword,
            isFullWidth: true,
            iconPath: AppIcons.checkCircle,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField({
    required int index,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color textColor,
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
        style: AppTypography.h1.copyWith(color: textColor),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onOtpChanged(index, value),
      ),
    );
  }

  Widget _buildRequirement(String text, Color textColor) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.spacingXS),
      child: Row(
        children: [
          AppSvgIcon(
            assetPath: AppIcons.check,
            size: 16,
            color: AppColors.onlineGreen,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Text(
            text,
            style: AppTypography.caption.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
