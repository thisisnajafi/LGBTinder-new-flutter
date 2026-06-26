// Screen: AccountManagementScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
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
  const AccountManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen> {
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangeEmail() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post<Map<String, dynamic>>(
        ApiEndpoints.changeEmail,
        data: {'email': newEmail},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Verification Code Sent',
          message: 'A verification code has been sent to $newEmail. Please check your email and enter the code below.',
          icon: Icons.email,
          iconColor: Theme.of(context).colorScheme.primary,
        );
        // Show verification code input dialog
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

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
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
          'current_password': _currentPasswordController.text,
          'password': _newPasswordController.text,
          'password_confirmation': _confirmPasswordController.text,
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
          icon: Icons.check_circle,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35);

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
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: const BorderSide(
                            color: AppColors.accentViolet,
                            width: 2,
                          ),
                        ),
                        prefixIcon:
                            Icon(Icons.email, color: secondaryTextColor),
                      ),
                      style: AppTypography.body.copyWith(color: textColor),
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
                    icon: Icons.save,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXL),
                PremiumSettingsGroup(
                  title: 'Change password',
                  children: [
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: const BorderSide(
                            color: AppColors.accentViolet,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(Icons.lock_outline,
                            color: secondaryTextColor),
                      ),
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                    const SizedBox(height: AppSpacing.spacingMD),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: const BorderSide(
                            color: AppColors.accentViolet,
                            width: 2,
                          ),
                        ),
                        prefixIcon:
                            Icon(Icons.lock, color: secondaryTextColor),
                      ),
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                    const SizedBox(height: AppSpacing.spacingMD),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: const BorderSide(
                            color: AppColors.accentViolet,
                            width: 2,
                          ),
                        ),
                        prefixIcon:
                            Icon(Icons.lock, color: secondaryTextColor),
                      ),
                      style: AppTypography.body.copyWith(color: textColor),
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
                    icon: Icons.lock_reset,
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
                      icon: Icons.support_agent,
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
                  TextFormField(
                    controller: verificationCodeController,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      hintText: '000000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      ),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the verification code';
                      }
                      if (value.length != 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
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
                                  icon: Icons.check_circle,
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
