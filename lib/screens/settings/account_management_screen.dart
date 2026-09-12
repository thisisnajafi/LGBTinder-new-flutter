// Screen: AccountManagementScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_settings_detail.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';
import '../../core/constants/api_endpoints.dart';
import '../../routes/app_router.dart';
import '../../core/providers/api_providers.dart';
import '../../features/profile/providers/profile_page_cache_provider.dart';
import '../../features/profile/providers/profile_providers.dart';

/// Account management screen - Manage account settings
class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen> {
  final _emailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  static final _passwordComplexity = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileEmail());
  }

  void _loadProfileEmail() {
    final profile = ref.read(profilePageCacheProvider).valueOrNull?.profile;
    final email = profile?.email;
    if (email != null &&
        email.isNotEmpty &&
        email != 'user@unknown.com' &&
        mounted) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangeEmail() async {
    final newEmail = _emailController.text.trim();
    final password = _emailPasswordController.text;
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your current password to change email')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post<Map<String, dynamic>>(
        ApiEndpoints.changeEmail,
        data: {'new_email': newEmail, 'password': password},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }

      if (mounted) {
        _emailPasswordController.clear();
        AlertDialogCustom.show(
          context,
          title: 'Verification Code Sent',
          message: 'A verification code has been sent to $newEmail. Please check your email and enter the code below.',
          iconPath: AppIcons.email,
          iconColor: Theme.of(context).colorScheme.primary,
        );
        await _showEmailVerificationDialog(newEmail);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification code: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 8 ||
        !_passwordComplexity.hasMatch(_newPasswordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 8 characters and include uppercase, lowercase, a number, and a symbol',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post<Map<String, dynamic>>(
        ApiEndpoints.changePassword,
        data: {
          'old_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
          'new_password_confirmation': _confirmPasswordController.text,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        AlertDialogCustom.show(
          context,
          title: 'Password Changed',
          message: 'Your password has been successfully updated',
          iconPath: AppIcons.checkCircle,
          iconColor: AppColors.onlineGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return AppSettingsDetailScaffold(
      title: 'Account management',
      subtitle: 'Update email and password',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AppSettingsDetailList(
              children: [
                PremiumSettingsGroup(
                  title: 'Email address',
                  children: [
                    PremiumTextField(
                      controller: _emailPasswordController,
                      label: 'Current password',
                      hintText: 'Enter your current password',
                      obscureText: true,
                      prefixIconPath: AppIcons.lock,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                    ),
                    const SizedBox(height: AppSpacing.spacingMD),
                    PremiumTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIconPath: AppIcons.email,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSettingsLayout.horizontalPadding,
                    AppSpacing.spacingXL,
                    AppSettingsLayout.horizontalPadding,
                    0,
                  ),
                  child: GradientButton(
                    text: 'Update email',
                    onPressed: _handleChangeEmail,
                    isFullWidth: true,
                    iconPath: AppIcons.save,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXL),
                PremiumSettingsGroup(
                  title: 'Change password',
                  children: [
                    PremiumTextField(
                      controller: _currentPasswordController,
                      label: 'Current password',
                      hintText: 'Enter your current password',
                      obscureText: true,
                      prefixIconPath: AppIcons.lockOutline,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                    ),
                    const SizedBox(height: AppSpacing.spacingMD),
                    PremiumTextField(
                      controller: _newPasswordController,
                      label: 'New password',
                      hintText: 'At least 8 characters',
                      obscureText: true,
                      prefixIconPath: AppIcons.lock,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                    ),
                    const SizedBox(height: AppSpacing.spacingMD),
                    PremiumTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm new password',
                      hintText: 'Re-enter the new password',
                      obscureText: true,
                      prefixIconPath: AppIcons.lock,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSettingsLayout.horizontalPadding,
                    AppSpacing.spacingXL,
                    AppSettingsLayout.horizontalPadding,
                    0,
                  ),
                  child: GradientButton(
                    text: 'Change password',
                    onPressed: _handleChangePassword,
                    isFullWidth: true,
                    iconPath: AppIcons.lockReset,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXL),
                PremiumSettingsGroup(
                  title: 'Need help with your account?',
                  children: [
                    Text(
                      'To request account removal, contact our support team. '
                      'An administrator will review your request.',
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                    const SizedBox(height: AppSpacing.spacingMD),
                    GradientButton(
                      text: 'Contact support',
                      onPressed: () => context.push(AppRoutes.supportTickets),
                      isFullWidth: true,
                      iconPath: AppIcons.support,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _showEmailVerificationDialog(String newEmail) async {
    final verificationCodeController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusLG),
              ),
              title: Text(
                'Verify Email Change',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter the 6-digit verification code sent to:',
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  Text(
                    newEmail,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingLG),
                  PremiumTextField(
                    controller: verificationCodeController,
                    label: 'Verification code',
                    hintText: '000000',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    prefixIconPath: AppIcons.email,
                    autocorrect: false,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.button.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (verificationCodeController.text.length == 6) {
                            setState(() => isLoading = true);

                            try {
                              await ref.read(profileServiceProvider).verifyEmailChange(
                                verificationCodeController.text,
                              );

                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                                AlertDialogCustom.show(
                                  context,
                                  title: 'Email Updated',
                                  message: 'Your email address has been successfully updated to $newEmail.',
                                  iconPath: AppIcons.checkCircle,
                                  iconColor: AppColors.onlineGreen,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Verification failed: $e'),
                                    backgroundColor: AppColors.notificationRed,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid 6-digit code'),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
