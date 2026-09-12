// Screen: ProfileBackupScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Profile backup screen - Backup profile data
class ProfileBackupScreen extends ConsumerStatefulWidget {
  const ProfileBackupScreen({super.key});

  @override
  ConsumerState<ProfileBackupScreen> createState() =>
      _ProfileBackupScreenState();
}

class _ProfileBackupScreenState extends ConsumerState<ProfileBackupScreen> {
  final ValueNotifier<bool> _isBackingUp = ValueNotifier(false);
  final ValueNotifier<double> _backupProgress = ValueNotifier(0);
  bool _autoBackupEnabled = false;
  String? _lastBackupDate;
  String _backupFrequency = 'weekly';

  @override
  void dispose() {
    _isBackingUp.dispose();
    _backupProgress.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    setState(() {
      _autoBackupEnabled = false;
      _lastBackupDate = null;
      _backupFrequency = 'weekly';
    });
  }

  Future<void> _createBackup() async {
    _isBackingUp.value = true;
    _backupProgress.value = 0;
    try {
      for (var step = 1; step <= 10; step++) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        _backupProgress.value = step / 10;
      }
      if (!mounted) return;
      setState(() {
        _lastBackupDate = DateTime.now().toIso8601String();
      });
      AlertDialogCustom.show(
        context,
        title: 'Backup Created',
        message: 'Your profile backup has been created successfully!',
        iconPath: AppIcons.checkCircle,
        iconColor: AppColors.onlineGreen,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        _isBackingUp.value = false;
        _backupProgress.value = 0;
      }
    }
  }

  Future<void> _restoreBackup() async {
    AlertDialogCustom.show(
      context,
      title: 'Restore Backup',
      message: 'Backup restoration coming soon',
      iconPath: AppIcons.refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return AppPageScaffold(
      title: 'Profile Backup',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          const SectionHeader(
            title: 'Backup Your Profile',
            iconPath: AppIcons.archive,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Keep your profile data safe with automatic backups',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          if (_lastBackupDate != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              margin: EdgeInsets.only(bottom: AppSpacing.spacingLG),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: AppColors.onlineGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.checkCircle,
                    size: 24,
                    color: AppColors.onlineGreen,
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Backup',
                          style: AppTypography.body.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          _formatDate(_lastBackupDate!),
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SectionHeader(
            title: 'Manual Backup',
            iconPath: AppIcons.save,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ValueListenableBuilder<bool>(
            valueListenable: _isBackingUp,
            builder: (context, backingUp, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GradientButton(
                    text: backingUp ? 'Creating Backup...' : 'Create Backup Now',
                    onPressed: backingUp ? null : _createBackup,
                    isLoading: backingUp,
                    isFullWidth: true,
                    iconPath: AppIcons.archive,
                  ),
                  if (backingUp) ...[
                    SizedBox(height: AppSpacing.spacingMD),
                    ValueListenableBuilder<double>(
                      valueListenable: _backupProgress,
                      builder: (context, progress, _) {
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentPurple,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'Automatic Backup',
            iconPath: AppIcons.clock,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Auto Backup',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        'Automatically backup your profile',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoBackupEnabled,
                  onChanged: (value) {
                    setState(() => _autoBackupEnabled = value);
                  },
                  activeThumbColor: AppColors.accentPurple,
                ),
              ],
            ),
          ),
          if (_autoBackupEnabled) ...[
            SizedBox(height: AppSpacing.spacingMD),
            const SectionHeader(
              title: 'Backup Frequency',
              iconPath: AppIcons.refresh,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildFrequencyOption(
              'Daily',
              'daily',
              AppIcons.calendar1,
              textColor,
              secondaryTextColor,
              surfaceColor,
              borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildFrequencyOption(
              'Weekly',
              'weekly',
              AppIcons.calendar2,
              textColor,
              secondaryTextColor,
              surfaceColor,
              borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildFrequencyOption(
              'Monthly',
              'monthly',
              AppIcons.calendarTick,
              textColor,
              secondaryTextColor,
              surfaceColor,
              borderColor,
            ),
          ],
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'Restore Backup',
            iconPath: AppIcons.refresh,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.warningYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: AppColors.warningYellow.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.warning,
                      size: 24,
                      color: AppColors.warningYellow,
                    ),
                    SizedBox(width: AppSpacing.spacingMD),
                    Expanded(
                      child: Text(
                        'Restore from Backup',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Restoring a backup will replace your current profile data. Make sure you have a recent backup before proceeding.',
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                GradientButton(
                  text: 'Restore Backup',
                  onPressed: _restoreBackup,
                  isFullWidth: true,
                  iconPath: AppIcons.refresh,
                ),
              ],
            ),
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'What\'s Backed Up',
            iconPath: AppIcons.infoCircle,
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
                _buildBackupItem('Profile Information', textColor),
                _buildBackupItem('Photos', textColor),
                _buildBackupItem('Settings', textColor),
                _buildBackupItem('Preferences', textColor),
                _buildBackupItem('Match History', textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(
    String label,
    String value,
    String iconPath,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isSelected = _backupFrequency == value;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isSelected ? AppColors.accentPurple : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _backupFrequency = value),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              AppSvgIcon(
                assetPath: iconPath,
                size: 22,
                color: isSelected
                    ? AppColors.accentPurple
                    : secondaryTextColor,
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: AppText(
                  label,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                ),
              ),
              if (isSelected)
                AppSvgIcon(
                  assetPath: AppIcons.checkCircle,
                  size: 22,
                  color: AppColors.accentPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupItem(String text, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingXS),
      child: Row(
        children: [
          AppSvgIcon(
            assetPath: AppIcons.check,
            size: 16,
            color: AppColors.onlineGreen,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: AppText(
              text,
              style: AppTypography.body.copyWith(color: textColor),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
