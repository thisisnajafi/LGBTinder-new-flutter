import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../routes/app_router.dart';

/// Self-serve, permanent account deletion (Google Play / App Store requirement).
///
/// Backend: DELETE /auth/delete-account. Email accounts confirm with their password;
/// Google/Apple accounts without a password confirm with `confirmation: DELETE`.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  static const _confirmWord = 'DELETE';
  static const _playSubscriptionsUrl = 'https://play.google.com/store/account/subscriptions';
  static const _appleSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _canSubmit => !_busy && _confirmController.text.trim() == _confirmWord;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _openSubscriptions() async {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final uri = Uri.parse(isIos ? _appleSubscriptionsUrl : _playSubscriptionsUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _delete() async {
    if (!_canSubmit) return;

    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account permanently?'),
        content: const Text(
          'Your profile, photos, messages, matches and all other personal data will be '
          'erased. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.feedbackError),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final password = _passwordController.text;
      final response = await api.delete<Map<String, dynamic>>(
        ApiEndpoints.authDeleteAccount,
        data: {
          if (password.isNotEmpty) 'password': password,
          'confirmation': _confirmWord,
        },
        fromJson: (json) => json is Map<String, dynamic> ? json : <String, dynamic>{},
      );
      if (!response.isSuccess) {
        throw ApiError(
          message: response.message,
        );
      }
      await _clearLocalData();
      if (!mounted) return;
      context.go(AppRoutes.welcome);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } catch (e, st) {
      AppLogger.error('Account deletion failed', tag: 'DeleteAccount', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _messageFor(e);
      });
    }
  }

  String _messageFor(Object e) => deleteAccountErrorMessage(
        e,
        passwordEmpty: _passwordController.text.isEmpty,
      );

  Future<void> _clearLocalData() async {
    try {
      await ref.read(authProvider.notifier).logout(silent: true);
    } catch (_) {
      // Token is already revoked server-side; continue clearing local data.
    }
    try {
      await const FlutterSecureStorage().deleteAll();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7));

    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.feedbackError.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.feedbackError.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This is permanent',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.feedbackError, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'Deleting your account erases your profile, photos, messages, matches, likes, '
                    'emergency contacts and location. You will be signed out on all devices and '
                    'cannot recover the account.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Purchase records are kept for up to 7 years for tax and refund purposes, and '
                    'records of serious rule violations for up to 2 years.',
                    style: muted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Have a subscription?', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text(
                    'Deleting your account does not cancel a Google Play or App Store subscription. '
                    'Cancel it in the store first so you are not charged again.',
                  ),
                  TextButton(
                    onPressed: _openSubscriptions,
                    child: const Text('Manage subscriptions in the store'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Current password', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('delete_account_password'),
              controller: _passwordController,
              obscureText: _obscure,
              enabled: !_busy,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Current password',
                hintText: 'Enter your account password (not your email)',
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                helperText: 'Leave empty if you signed in with Google or Apple and never set a password.',
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Confirm deletion', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('delete_account_confirm'),
              controller: _confirmController,
              enabled: !_busy,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Confirmation',
                hintText: 'Type DELETE to confirm',
                helperText: 'Type DELETE in capital letters to enable the button.',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: AppColors.feedbackError)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canSubmit ? _delete : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.feedbackError,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Delete my account'),
            ),
          ],
        ),
      ),
    );
  }
}

const kDeleteAccountWrongPassword = 'Incorrect password. Please try again.';
const kDeleteAccountGenericError =
    'We couldn\'t delete your account right now. Please try again, or contact support@lgbtfinder.com.';

/// Friendly, user-facing message for a failed account deletion.
/// Never returns a raw exception / ApiError string.
String deleteAccountErrorMessage(Object e, {bool passwordEmpty = false}) {
  int? status;
  String? message;
  if (e is ApiError) {
    status = e.code;
    message = e.message;
    final original = e.originalError;
    if (status == null && original is DioException) {
      status = original.response?.statusCode;
    }
  } else if (e is DioException) {
    status = e.response?.statusCode;
    final data = e.response?.data;
    message = data is Map ? data['message']?.toString() : null;
    if (status == null &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout)) {
      return 'No connection. Check your internet and try again.';
    }
  }
  final lower = (message ?? e.toString()).toLowerCase();
  if (status == 401 || lower.contains('invalid password') || lower.contains('incorrect password')) {
    return kDeleteAccountWrongPassword;
  }
  if (status == 422 && passwordEmpty) {
    return 'Please enter your current password. If you signed in with Google or Apple and never set one, leave it empty and type DELETE.';
  }
  return kDeleteAccountGenericError;
}
