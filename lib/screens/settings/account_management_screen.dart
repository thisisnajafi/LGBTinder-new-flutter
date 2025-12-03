// Screen: AccountManagementScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/confirmation_dialog.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Account management screen - Manage account settings
class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen> {
  final _emailController = TextEditingController(text: 'user@example.com');
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

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
      // TODO: Change email via API
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Email Updated',
          message: 'A verification email has been sent to $newEmail',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update email: $e')),
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
      // TODO: Change password via API
      await Future.delayed(const Duration(seconds: 1));
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

  Future<void> _handleDeleteAccount() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Account',
      message: 'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
      confirmText: 'Delete Account',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Delete account via API
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          // TODO: Navigate to login/welcome screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
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
        title: 'Account Management',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              children: [
                // Email
                SectionHeader(
                  title: 'Email Address',
                  icon: Icons.email,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingMD),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.surfaceElevatedLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                      ),
                      prefixIcon: Icon(Icons.email, color: secondaryTextColor),
                    ),
                    style: AppTypography.body.copyWith(color: textColor),
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                GradientButton(
                  text: 'Update Email',
                  onPressed: _handleChangeEmail,
                  isFullWidth: true,
                  icon: Icons.save,
                ),
                DividerCustom(),
                SizedBox(height: AppSpacing.spacingLG),

                // Change password
                SectionHeader(
                  title: 'Change Password',
                  icon: Icons.lock,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingMD),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceElevatedDark
                              : AppColors.surfaceElevatedLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                          ),
                          prefixIcon: Icon(Icons.lock_outline, color: secondaryTextColor),
                        ),
                        style: AppTypography.body.copyWith(color: textColor),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceElevatedDark
                              : AppColors.surfaceElevatedLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                          ),
                          prefixIcon: Icon(Icons.lock, color: secondaryTextColor),
                        ),
                        style: AppTypography.body.copyWith(color: textColor),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceElevatedDark
                              : AppColors.surfaceElevatedLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                          ),
                          prefixIcon: Icon(Icons.lock, color: secondaryTextColor),
                        ),
                        style: AppTypography.body.copyWith(color: textColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                GradientButton(
                  text: 'Change Password',
                  onPressed: _handleChangePassword,
                  isFullWidth: true,
                  icon: Icons.lock_reset,
                ),
                DividerCustom(),
                SizedBox(height: AppSpacing.spacingLG),

                // Danger zone
                SectionHeader(
                  title: 'Danger Zone',
                  icon: Icons.warning,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  decoration: BoxDecoration(
                    color: AppColors.notificationRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(color: AppColors.notificationRed),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: AppColors.notificationRed,
                            size: 24,
                          ),
                          SizedBox(width: AppSpacing.spacingSM),
                          Text(
                            'Delete Account',
                            style: AppTypography.h3.copyWith(
                              color: AppColors.notificationRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      Text(
                        'Once you delete your account, there is no going back. Please be certain.',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      OutlinedButton(
                        onPressed: _handleDeleteAccount,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                          side: BorderSide(color: AppColors.notificationRed, width: 2),
                        ),
                        child: Text(
                          'Delete My Account',
                          style: AppTypography.button.copyWith(
                            color: AppColors.notificationRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
              ],
            ),
    );
  }
}
