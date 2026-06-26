// Screen: TwoFactorAuthScreen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/cache/cache_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/alert_dialog_custom.dart';
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';

/// Two-factor authentication screen - Setup 2FA
class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  const TwoFactorAuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends ConsumerState<TwoFactorAuthScreen> {
  bool _isEnabled = false;
  bool _isLoading = false;
  bool _showVerificationStep = false;
  String? _qrCodeUrl;
  final List<String> _backupCodes = [];
  int _backupCodesCount = 0;

  @override
  void initState() {
    super.initState();
    _load2FAStatus();
  }

  Future<void> _load2FAStatus() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<Map<String, dynamic>>(
        ApiEndpoints.twoFactorStatus,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        setState(() {
          _isEnabled = data['enabled'] ?? false;
          _backupCodesCount = data['backup_codes_count'] ?? 0;
        });
      }
    } catch (e) {
      // On error, keep defaults (disabled)
      setState(() {
        _isEnabled = false;
        _backupCodesCount = 0;
      });
    }
  }

  Future<void> _enable2FA() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, enable 2FA to get the secret
      final enableResponse = await ref.read(apiServiceProvider).post<Map<String, dynamic>>(
        ApiEndpoints.twoFactorEnable,
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!enableResponse.isSuccess) {
        throw Exception('Failed to enable 2FA');
      }

      // Then get the QR code
      final qrResponse = await ref.read(apiServiceProvider).get<Map<String, dynamic>>(
        ApiEndpoints.twoFactorQrCode,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Then get backup codes
      final backupResponse = await ref.read(apiServiceProvider).post<Map<String, dynamic>>(
        ApiEndpoints.twoFactorBackupCodes,
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (qrResponse.isSuccess && qrResponse.data != null &&
          backupResponse.isSuccess && backupResponse.data != null) {
        final qrData = qrResponse.data!;
        final backupData = backupResponse.data!;

        setState(() {
          _qrCodeUrl = qrData['qr_code_url'] ?? '';
          _backupCodes.clear();
          _backupCodes.addAll(List<String>.from(backupData['backup_codes'] ?? []));
          _isEnabled = false; // Still need to verify
          _isLoading = false;
          _showVerificationStep = true;
        });
      } else {
        throw Exception('Failed to get QR code or backup codes');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enable 2FA: $e')),
      );
    }
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: const Text('Are you sure you want to disable two-factor authentication? This will make your account less secure.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.notificationRed,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.post<Map<String, dynamic>>(
          ApiEndpoints.twoFactorDisable,
          data: {},
          fromJson: (json) => json as Map<String, dynamic>,
        );

        setState(() {
          _isEnabled = false;
          _qrCodeUrl = null;
          _backupCodes.clear();
          _backupCodesCount = 0;
          _showVerificationStep = false;
          _isLoading = false;
        });

        AlertDialogCustom.show(
          context,
          title: '2FA Disabled',
          message: 'Two-factor authentication has been disabled',
          iconPath: AppIcons.info,
          iconColor: AppColors.feedbackWarning,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disable 2FA: $e')),
        );
      }
    }
  }

  Future<void> _verify2FACode(String code) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post<Map<String, dynamic>>(
        ApiEndpoints.twoFactorVerify,
        data: {'code': code},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        await _load2FAStatus(); // Reload status to confirm it's enabled
        setState(() {
          _showVerificationStep = false;
          _isLoading = false;
        });

        AlertDialogCustom.show(
          context,
          title: '2FA Enabled',
          message: 'Two-factor authentication has been successfully enabled. Make sure to save your backup codes.',
          iconPath: AppIcons.shieldTick,
          iconColor: AppColors.onlineGreen,
        );
      } else {
        throw Exception('Invalid verification code');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    // TODO: Copy to clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copy to clipboard functionality will be implemented')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final surfaceColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.35);

    return AppSettingsDetailScaffold(
      title: 'Two-factor authentication',
      subtitle: 'Extra protection for your account',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AppSettingsDetailList(
              children: [
                PremiumSettingsGroup(
                  title: 'Status',
                  children: [
                    PremiumInfoRow(
                      label: 'Two-factor authentication',
                      value: _isEnabled ? 'Enabled' : 'Disabled',
                      badge: _isEnabled ? 'Active' : null,
                    ),
                    if (_isEnabled && _backupCodesCount > 0)
                      PremiumInfoRow(
                        label: 'Backup codes remaining',
                        value: '$_backupCodesCount',
                      ),
                  ],
                ),
                AppSettingsSectionFootnote(
                  text: _isEnabled
                      ? 'Your account is protected with two-factor authentication.'
                      : 'Enable 2FA to add an extra layer of security to your account.',
                ),

                if (!_isEnabled) ...[
                  const SizedBox(height: AppSpacing.spacingXL),
                  PremiumSettingsGroup(
                    title: 'How it works',
                    children: [
                      _buildInstructionStep(
                        number: '1',
                        title: 'Scan QR code',
                        description:
                            'Use an authenticator app to scan the QR code',
                      ),
                      _buildInstructionStep(
                        number: '2',
                        title: 'Enter code',
                        description:
                            'Enter the 6-digit code from your authenticator app',
                      ),
                      _buildInstructionStep(
                        number: '3',
                        title: 'Save backup codes',
                        description: 'Keep your backup codes in a safe place',
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
                      text: 'Enable 2FA',
                      onPressed: _enable2FA,
                      isFullWidth: true,
                      iconPath: AppIcons.shield,
                    ),
                  ),
                ] else ...[
                  if (_qrCodeUrl != null) ...[
                    const SizedBox(height: AppSpacing.spacingXL),
                    PremiumSettingsGroup(
                      title: 'QR code',
                      children: [
                        Center(
                          child: CachedNetworkImage(
                            imageUrl: _qrCodeUrl!,
                            cacheManager: ref.watch(imageCacheServiceProvider),
                            fadeInDuration: const Duration(milliseconds: 200),
                            width: 200,
                            height: 200,
                            errorWidget: (context, url, error) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: surfaceColor,
                                child: AppSvgIcon(
                                  assetPath: AppIcons.getIconPath('scan-barcode'),
                                  size: 100,
                                  color: secondaryTextColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_showVerificationStep) ...[
                    const SizedBox(height: AppSpacing.spacingXL),
                    PremiumSettingsGroup(
                      title: 'Verify setup',
                      children: [
                        Text(
                          'Enter the 6-digit code from your authenticator app to complete setup:',
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacingMD),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Verification code',
                            hintText: '000000',
                            prefixIcon: AppSvgIcon(
                              assetPath: AppIcons.timer,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: (value) {
                            if (value.length == 6) {
                              _verify2FACode(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  if (_backupCodes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.spacingXL),
                    PremiumSettingsGroup(
                      title: 'Backup codes',
                      children: [
                        Text(
                          'Save these codes in a safe place. You can use them to access your account if you lose your device.',
                          style: AppTypography.body.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacingMD),
                        for (final code in _backupCodes)
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.spacingSM,
                            ),
                            padding: const EdgeInsets.all(AppSpacing.spacingMD),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? AppColors.cardBackgroundDark
                                  : AppColors.cardBackgroundLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.radiusLG),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  code,
                                  style: AppTypography.h3.copyWith(
                                    color: textColor,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                IconButton(
                                  icon: AppSvgIcon(
                                    assetPath: AppIcons.copy,
                                    size: 20,
                                    color: AppColors.accentViolet,
                                  ),
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: code),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Backup code copied to clipboard',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSettingsLayout.horizontalPadding,
                      AppSpacing.spacingXL,
                      AppSettingsLayout.horizontalPadding,
                      0,
                    ),
                    child: OutlinedButton(
                    onPressed: _disable2FA,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                      side: BorderSide(color: AppColors.notificationRed),
                    ),
                    child: Text(
                      'Disable 2FA',
                      style: AppTypography.button.copyWith(
                        color: AppColors.notificationRed,
                      ),
                    ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.accentViolet,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXS),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
