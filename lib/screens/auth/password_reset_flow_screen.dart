// Screen: PasswordResetFlowScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/navigation/auth_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/auth_page_scaffold.dart';
import '../../features/auth/data/models/models.dart';
import '../../features/auth/presentation/widgets/password_reset_steps.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Password reset flow — email → OTP → new password.
class PasswordResetFlowScreen extends ConsumerStatefulWidget {
  const PasswordResetFlowScreen({super.key});

  @override
  ConsumerState<PasswordResetFlowScreen> createState() =>
      _PasswordResetFlowScreenState();
}

class _PasswordResetFlowScreenState
    extends ConsumerState<PasswordResetFlowScreen> {
  final _pageController = PageController();
  final _currentStep = ValueNotifier<int>(0);
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _isSendingOtp = ValueNotifier<bool>(false);
  final _isVerifyingOtp = ValueNotifier<bool>(false);
  final _isResettingPassword = ValueNotifier<bool>(false);
  String? _verifiedOtpCode;

  @override
  void dispose() {
    _pageController.dispose();
    _currentStep.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _isSendingOtp.dispose();
    _isVerifyingOtp.dispose();
    _isResettingPassword.dispose();
    super.dispose();
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

  Future<void> _goToStep(int step) async {
    _currentStep.value = step;
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      step,
      duration: AppAnimations.pageTransitionDuration(context),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    _isSendingOtp.value = true;
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendOtp(
        SendOtpRequest(email: _emailController.text.trim()),
      );
      if (mounted) {
        await _goToStep(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
        );
      }
    } finally {
      if (mounted) {
        _isSendingOtp.value = false;
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

    _isVerifyingOtp.value = true;
    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyOtp(
        VerifyOtpRequest(
          email: _emailController.text.trim(),
          code: code,
        ),
      );
      if (mounted) {
        _verifiedOtpCode = code;
        await _goToStep(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid or expired code: $e')),
        );
        for (final controller in _otpControllers) {
          controller.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        _isVerifyingOtp.value = false;
      }
    }
  }

  Future<bool> _resendOtp() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendOtp(
        SendOtpRequest(email: _emailController.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: $e')),
        );
      }
      return false;
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

    _isResettingPassword.value = true;
    try {
      final code = _verifiedOtpCode ?? _getOtpCode();
      if (code.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify the OTP code first')),
        );
        return;
      }

      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(
        ResetPasswordRequest(
          email: _emailController.text.trim(),
          code: code,
          password: _passwordController.text.trim(),
          passwordConfirmation: _confirmPasswordController.text.trim(),
        ),
      );

      if (mounted) {
        await AlertDialogCustom.show(
          context,
          title: 'Password Reset',
          message:
              'Your password has been reset successfully! You can now login with your new password.',
          iconPath: AppIcons.checkCircle,
          iconColor: AppColors.onlineGreen,
        );
        if (!mounted) return;
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(AppRoutes.login);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password: $e')),
        );
      }
    } finally {
      if (mounted) {
        _isResettingPassword.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      title: 'Reset Password',
      subtitle: 'Recover access to your account',
      onBack: () {
        final step = _currentStep.value;
        if (step > 0) {
          _goToStep(step - 1);
        } else {
          AuthNavigation.popOrWelcome(context);
        }
      },
      body: ValueListenableBuilder<int>(
        valueListenable: _currentStep,
        builder: (context, step, _) {
          return Column(
            children: [
              PasswordResetProgress(currentStep: step),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    RepaintBoundary(
                      child: ResetEmailStep(
                        emailController: _emailController,
                        isSending: _isSendingOtp,
                        onSend: _sendOtp,
                      ),
                    ),
                    RepaintBoundary(
                      child: step >= 1
                          ? ResetOtpStep(
                              email: _emailController.text.trim(),
                              otpControllers: _otpControllers,
                              otpFocusNodes: _otpFocusNodes,
                              isVerifying: _isVerifyingOtp,
                              onChanged: _onOtpChanged,
                              onVerify: _verifyOtp,
                              onResend: _resendOtp,
                            )
                          : const SizedBox.expand(),
                    ),
                    RepaintBoundary(
                      child: step >= 2
                          ? ResetPasswordStep(
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              isResetting: _isResettingPassword,
                              onReset: _resetPassword,
                            )
                          : const SizedBox.expand(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
