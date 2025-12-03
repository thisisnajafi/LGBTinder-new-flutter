// Screen: TwoFactorAuthScreen
import 'package:flutter/material.dart';
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

/// Two-factor authentication screen - Setup 2FA
class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  const TwoFactorAuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends ConsumerState<TwoFactorAuthScreen> {
  bool _isEnabled = false;
  bool _isLoading = false;
  String? _qrCodeUrl;
  final List<String> _backupCodes = [];

  @override
  void initState() {
    super.initState();
    _load2FAStatus();
  }

  Future<void> _load2FAStatus() async {
    // TODO: Load 2FA status from API
    setState(() {
      _isEnabled = false;
    });
  }

  Future<void> _enable2FA() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Enable 2FA via API and get QR code
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _qrCodeUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=otpauth://totp/LGBTinder?secret=JBSWY3DPEHPK3PXP';
        _backupCodes.addAll([
          '1234-5678',
          '2345-6789',
          '3456-7890',
          '4567-8901',
          '5678-9012',
        ]);
        _isEnabled = true;
        _isLoading = false;
      });
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
        // TODO: Disable 2FA via API
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isEnabled = false;
          _qrCodeUrl = null;
          _backupCodes.clear();
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
                                      onPressed: () {
                                        // TODO: Copy to clipboard
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Copied: $code')),
                                        );
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
