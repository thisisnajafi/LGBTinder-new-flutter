import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/providers/api_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_settings_detail.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../features/profile/providers/profile_page_cache_provider.dart';
import '../../shared/services/token_storage_service.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Current / new / confirm password, or a first-time set for social sign-in.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  static final _passwordComplexity = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$',
  );

  bool get _requiresCurrent {
    final profile = ref.watch(profilePageCacheProvider).valueOrNull?.profile;
    final data = profile?.additionalData;
    final raw = data == null ? null : data['requires_current_password'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) return raw != 'false' && raw != '0';
    return true;
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (_requiresCurrent && _currentController.text.isEmpty) {
      _showMessage('Enter your current password');
      return;
    }
    if (_newController.text != _confirmController.text) {
      _showMessage('Passwords do not match');
      return;
    }
    if (_newController.text.length < 8 ||
        !_passwordComplexity.hasMatch(_newController.text)) {
      _showMessage(
        'Password must be at least 8 characters and include uppercase, lowercase, a number, and a symbol',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiServiceProvider).post<Map<String, dynamic>>(
            ApiEndpoints.changePassword,
            data: {
              if (_requiresCurrent) 'old_password': _currentController.text,
              'new_password': _newController.text,
              'new_password_confirmation': _confirmController.text,
            },
            fromJson: (json) => json as Map<String, dynamic>,
          );
      if (!response.isSuccess) {
        throw Exception(response.message);
      }
      final body = response.data;
      final nested = body?['data'];
      final token = (nested is Map ? nested['token'] : null)?.toString() ??
          body?['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await TokenStorageService().saveAuthToken(token);
      }
      await ref.read(profilePageCacheProvider.notifier).refresh();
      if (!mounted) return;
      await AlertDialogCustom.show(
        context,
        title: _requiresCurrent ? 'Password changed' : 'Password set',
        message: _requiresCurrent
            ? 'Your sign-in password has been updated.'
            : 'You can now sign in with this password.',
        iconPath: AppIcons.checkCircle,
        iconColor: AppColors.onlineGreen,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showMessage('Failed to update password: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiresCurrent = _requiresCurrent;
    return AppSettingsDetailScaffold(
      title: requiresCurrent ? 'Change password' : 'Set a password',
      subtitle: requiresCurrent
          ? 'Update the password you use to sign in'
          : 'Add a password for this social sign-in account',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Password',
            children: [
              if (requiresCurrent) ...[
                PremiumTextField(
                  controller: _currentController,
                  label: 'Current password',
                  hintText: 'Enter your current password',
                  obscureText: true,
                  prefixIconPath: AppIcons.lockOutline,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                ),
                const SizedBox(height: AppSpacing.spacingMD),
              ],
              PremiumTextField(
                controller: _newController,
                label: 'New password',
                hintText: 'At least 8 characters',
                obscureText: true,
                prefixIconPath: AppIcons.lock,
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.spacingMD),
              PremiumTextField(
                controller: _confirmController,
                label: 'Confirm new password',
                hintText: 'Re-enter the new password',
                obscureText: true,
                prefixIconPath: AppIcons.lock,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                onSubmitted: (_) => _submit(),
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
              text: requiresCurrent ? 'Change password' : 'Set password',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              isFullWidth: true,
              iconPath: AppIcons.lockReset,
            ),
          ),
        ],
      ),
    );
  }
}
