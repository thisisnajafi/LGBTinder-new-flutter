// Screen: TwoFactorAuthScreen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/alert_dialog_custom.dart';
import '../core/constants/api_endpoints.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Two-Factor Authentication',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              children: [
                // Status card
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  decoration: BoxDecoration(
                    color: _isEnabled
                        ? AppColors.onlineGreen.withOpacity(0.2)
                        : AppColors.warningYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(
                      color: _isEnabled
                          ? AppColors.onlineGreen
                          : AppColors.warningYellow,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isEnabled ? Icons.verified : Icons.warning_amber,
                        color: _isEnabled
                            ? AppColors.onlineGreen
                            : AppColors.warningYellow,
                        size: 32,
                      ),
                      SizedBox(width: AppSpacing.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEnabled ? '2FA Enabled' : '2FA Disabled',
                              style: AppTypography.h2.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: AppSpacing.spacingXS),
                            Text(
                              _isEnabled
                                  ? 'Your account is protected with two-factor authentication'
                                  : 'Enable 2FA to add an extra layer of security',
                              style: AppTypography.body.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXXL),

                if (!_isEnabled) ...[
                  // Setup instructions
                  SectionHeader(
                    title: 'How It Works',
                    icon: Icons.info,
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  _buildInstructionStep(
                    number: '1',
                    title: 'Scan QR Code',
                    description: 'Use an authenticator app to scan the QR code',
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  _buildInstructionStep(
                    number: '2',
                    title: 'Enter Code',
                    description: 'Enter the 6-digit code from your authenticator app',
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  _buildInstructionStep(
                    number: '3',
                    title: 'Save Backup Codes',
                    description: 'Keep your backup codes in a safe place',
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                  GradientButton(
                    text: 'Enable 2FA',
                    onPressed: _enable2FA,
                    isFullWidth: true,
                    icon: Icons.security,
                  ),
                ] else ...[
                  // QR Code
                  if (_qrCodeUrl != null) ...[
                    SectionHeader(
                      title: 'QR Code',
                      icon: Icons.qr_code,
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(AppSpacing.spacingLG),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          border: Border.all(color: borderColor),
                        ),
                        child: Image.network(
                          _qrCodeUrl!,
                          width: 200,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
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
                    SizedBox(height: AppSpacing.spacingXXL),
                  ],

                  if (_showVerificationStep) ...[
                    SizedBox(height: AppSpacing.spacingLG),
                    SectionHeader(
                      title: 'Verify Setup',
                      icon: Icons.verified_user,
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.spacingLG),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        border: Border.all(color: borderColor),
                      ),
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

                  // Backup codes
                  if (_backupCodes.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Backup Codes',
                      icon: Icons.key,
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.spacingLG),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        border: Border.all(color: borderColor),
                      ),
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
                                  color: backgroundColor,
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
                    SizedBox(height: AppSpacing.spacingXXL),
                  ],
                  // Disable button
                  OutlinedButton(
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
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
        SizedBox(width: AppSpacing.spacingMD),
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
              SizedBox(height: AppSpacing.spacingXS),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
