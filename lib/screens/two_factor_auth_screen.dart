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
import '../core/widgets/app_grouped_list_card.dart';
import '../core/widgets/app_settings_detail.dart';
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
          icon: Icons.info,
          iconColor: AppColors.warningYellow,
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
          icon: Icons.verified,
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
      title: 'Two-Factor Authentication',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AppSettingsDetailList(
              children: [
                AppGroupedListSection(
                  title: 'Status',
                  padding: AppSettingsLayout.firstSectionPadding,
                  children: [
                    AppGroupedInfoTile(
                      label: 'Two-factor authentication',
                      value: _isEnabled ? 'Enabled' : 'Disabled',
                      badge: _isEnabled ? 'Active' : null,
                      showDivider: _isEnabled && _backupCodesCount > 0,
                    ),
                    if (_isEnabled && _backupCodesCount > 0)
                      AppGroupedInfoTile(
                        label: 'Backup codes remaining',
                        value: '$_backupCodesCount',
                        showDivider: false,
                      ),
                  ],
                ),
                AppSettingsSectionFootnote(
                  text: _isEnabled
                      ? 'Your account is protected with two-factor authentication.'
                      : 'Enable 2FA to add an extra layer of security to your account.',
                ),

                if (!_isEnabled) ...[
                  AppGroupedListSection(
                    title: 'How It Works',
                    padding: AppSettingsLayout.sectionPadding,
                    children: [
                      _buildInstructionStep(
                        number: '1',
                        title: 'Scan QR Code',
                        description:
                            'Use an authenticator app to scan the QR code',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        showDivider: true,
                      ),
                      _buildInstructionStep(
                        number: '2',
                        title: 'Enter Code',
                        description:
                            'Enter the 6-digit code from your authenticator app',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        showDivider: true,
                      ),
                      _buildInstructionStep(
                        number: '3',
                        title: 'Save Backup Codes',
                        description: 'Keep your backup codes in a safe place',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        showDivider: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: AppSettingsLayout.sectionPadding,
                    child: GradientButton(
                      text: 'Enable 2FA',
                      onPressed: _enable2FA,
                      isFullWidth: true,
                      icon: Icons.security,
                    ),
                  ),
                ] else ...[
                  // QR Code
                  if (_qrCodeUrl != null) ...[
                    AppGroupedListSection(
                      title: 'QR Code',
                      padding: AppSettingsLayout.sectionPadding,
                      children: [
                        AppSettingsInset(
                          child: Center(
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
                              child: Icon(
                                Icons.qr_code,
                                size: 100,
                                color: secondaryTextColor,
                              ),
                            );
                          },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_showVerificationStep) ...[
                    AppGroupedListSection(
                      title: 'Verify Setup',
                      padding: AppSettingsLayout.sectionPadding,
                      children: [
                        AppSettingsInset(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter the 6-digit code from your authenticator app to complete setup:',
                            style: AppTypography.bodyMedium.copyWith(
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Verification Code',
                              hintText: '000000',
                              prefixIcon: Icon(Icons.lock_clock, color: theme.colorScheme.onSurfaceVariant),
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
                        ),
                      ],
                    ),
                  ],

                  if (_backupCodes.isNotEmpty) ...[
                    AppGroupedListSection(
                      title: 'Backup Codes',
                      padding: AppSettingsLayout.sectionPadding,
                      children: [
                        AppSettingsInset(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Save these codes in a safe place. You can use them to access your account if you lose your device.',
                            style: AppTypography.body.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          ..._backupCodes.map((code) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                              child: Container(
                                padding: EdgeInsets.all(AppSpacing.spacingMD),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
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
                                      icon: Icon(
                                        Icons.copy,
                                        size: 20,
                                        color: AppColors.accentPurple,
                                      ),
                                      onPressed: () async {
                                        await Clipboard.setData(ClipboardData(text: code));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Backup code copied to clipboard'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  Padding(
                    padding: AppSettingsLayout.sectionPadding,
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
    required Color textColor,
    required Color secondaryTextColor,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSettingsInset(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.accentPurple,
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
        ),
        if (showDivider) const AppGroupedRowSeparator(),
      ],
    );
  }
}
