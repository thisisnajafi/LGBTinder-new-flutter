import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_text_field.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import 'email_verification_form.dart';

/// Email → Verify → Reset dots. Parent passes [currentStep] only.
class PasswordResetProgress extends StatelessWidget {
  const PasswordResetProgress({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      child: Row(
        children: [
          _ProgressDot(
            step: 0,
            label: 'Email',
            currentStep: currentStep,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          Expanded(
            child: ColoredBox(
              color: currentStep > 0 ? AppColors.accentPurple : borderColor,
              child: const SizedBox(height: 2),
            ),
          ),
          _ProgressDot(
            step: 1,
            label: 'Verify',
            currentStep: currentStep,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          Expanded(
            child: ColoredBox(
              color: currentStep > 1 ? AppColors.accentPurple : borderColor,
              child: const SizedBox(height: 2),
            ),
          ),
          _ProgressDot(
            step: 2,
            label: 'Reset',
            currentStep: currentStep,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({
    required this.step,
    required this.label,
    required this.currentStep,
    required this.textColor,
    required this.secondaryTextColor,
  });

  final int step;
  final String label;
  final int currentStep;
  final Color textColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final isActive = currentStep == step;
    final isCompleted = currentStep > step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? AppColors.accentPurple
                : secondaryTextColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? AppSvgIcon(
                  assetPath: AppIcons.check,
                  size: 20,
                  color: AppColors.textPrimaryDark,
                )
              : Center(
                  child: Text(
                    '${step + 1}',
                    style: AppTypography.body.copyWith(
                      color: isActive
                          ? AppColors.textPrimaryDark
                          : secondaryTextColor,
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
}

/// Step 0 — request OTP. Loading stays on [isSending].
class ResetEmailStep extends StatelessWidget {
  const ResetEmailStep({
    super.key,
    required this.emailController,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController emailController;
  final ValueNotifier<bool> isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
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
            "Enter your email address and we'll send you a verification code",
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          PremiumTextField(
            controller: emailController,
            label: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIconPath: AppIcons.emailOutlined,
            autocorrect: false,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          ValueListenableBuilder<bool>(
            valueListenable: isSending,
            builder: (context, sending, _) {
              return GradientButton(
                text: sending ? 'Sending...' : 'Send Verification Code',
                onPressed: sending ? null : onSend,
                isLoading: sending,
                isFullWidth: true,
                iconPath: AppIcons.sendIcon,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Step 1 — OTP. Countdown lives in [EmailResendRow].
class ResetOtpStep extends StatelessWidget {
  const ResetOtpStep({
    super.key,
    required this.email,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.isVerifying,
    required this.onChanged,
    required this.onVerify,
    required this.onResend,
  });

  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final ValueNotifier<bool> isVerifying;
  final void Function(int index, String value) onChanged;
  final VoidCallback onVerify;
  final Future<bool> Function() onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.spacingXXL),
          Center(
            child: AppSvgIcon(
              assetPath: AppIcons.shieldTick,
              size: 80,
              color: AppColors.accentViolet,
            ),
          ),
          SizedBox(height: AppSpacing.spacingXL),
          Text(
            'Enter Verification Code',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          AppText(
            "We've sent a 6-digit code to $email",
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          EmailOtpFields(
            controllers: otpControllers,
            focusNodes: otpFocusNodes,
            onChanged: onChanged,
          ),
          SizedBox(height: AppSpacing.spacingXL),
          ValueListenableBuilder<bool>(
            valueListenable: isVerifying,
            builder: (context, verifying, _) {
              return GradientButton(
                text: verifying ? 'Verifying...' : 'Verify Code',
                onPressed: verifying ? null : onVerify,
                isLoading: verifying,
                isFullWidth: true,
                iconPath: AppIcons.shieldTick,
              );
            },
          ),
          SizedBox(height: AppSpacing.spacingLG),
          EmailResendRow(onResend: onResend),
        ],
      ),
    );
  }
}

/// Step 2 — new password. Loading stays on [isResetting].
class ResetPasswordStep extends StatelessWidget {
  const ResetPasswordStep({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isResetting,
    required this.onReset,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueNotifier<bool> isResetting;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
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
            "Enter your new password. Make sure it's strong and secure.",
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          PremiumTextField(
            controller: passwordController,
            label: 'New password',
            hintText: 'Enter a strong password',
            obscureText: true,
            prefixIconPath: AppIcons.lock,
            autocorrect: false,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          PremiumTextField(
            controller: confirmPasswordController,
            label: 'Confirm password',
            hintText: 'Re-enter the new password',
            obscureText: true,
            prefixIconPath: AppIcons.lockOutline,
            autocorrect: false,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          const _PasswordRequirements(),
          SizedBox(height: AppSpacing.spacingXXL),
          ValueListenableBuilder<bool>(
            valueListenable: isResetting,
            builder: (context, resetting, _) {
              return GradientButton(
                text: resetting ? 'Resetting...' : 'Reset Password',
                onPressed: resetting ? null : onReset,
                isLoading: resetting,
                isFullWidth: true,
                iconPath: AppIcons.checkCircle,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements();

  static const _items = [
    'At least 8 characters',
    'One uppercase letter',
    'One lowercase letter',
    'One number',
    'One special character',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.3),
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
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacingXS),
              child: Row(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.check,
                    size: 16,
                    color: AppColors.onlineGreen,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Text(
                    item,
                    style: AppTypography.caption.copyWith(color: textColor),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
