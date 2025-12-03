// Screen: ProfileBackupScreen
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
import '../../widgets/modals/alert_dialog_custom.dart';

/// Profile backup screen - Backup profile data
class ProfileBackupScreen extends ConsumerStatefulWidget {
  const ProfileBackupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileBackupScreen> createState() => _ProfileBackupScreenState();
}

class _ProfileBackupScreenState extends ConsumerState<ProfileBackupScreen> {
  bool _isBackingUp = false;
  bool _autoBackupEnabled = false;
  String? _lastBackupDate;
  String _backupFrequency = 'weekly'; // 'daily', 'weekly', 'monthly'

  @override
  void initState() {
    super.initState();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    // TODO: Load backup settings from API
    setState(() {
      _autoBackupEnabled = false;
      _lastBackupDate = null;
      _backupFrequency = 'weekly';
    });
  }

  Future<void> _createBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      // TODO: Create backup via API
      // POST /api/profile/backup
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _lastBackupDate = DateTime.now().toIso8601String();
        });
        AlertDialogCustom.show(
          context,
          title: 'Backup Created',
          message: 'Your profile backup has been created successfully!',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    // TODO: Show backup selection dialog and restore
    AlertDialogCustom.show(
      context,
      title: 'Restore Backup',
      message: 'Backup restoration coming soon',
      icon: Icons.restore,
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
        title: 'Profile Backup',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          SectionHeader(
            title: 'Backup Your Profile',
            icon: Icons.backup,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Keep your profile data safe with automatic backups',
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Last backup
          if (_lastBackupDate != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              margin: EdgeInsets.only(bottom: AppSpacing.spacingLG),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: AppColors.onlineGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
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

          // Manual backup
          SectionHeader(
            title: 'Manual Backup',
            icon: Icons.save,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          GradientButton(
            text: _isBackingUp ? 'Creating Backup...' : 'Create Backup Now',
            onPressed: _isBackingUp ? null : _createBackup,
            isLoading: _isBackingUp,
            isFullWidth: true,
            icon: Icons.backup,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Auto backup
          SectionHeader(
            title: 'Automatic Backup',
            icon: Icons.schedule,
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
                    setState(() {
                      _autoBackupEnabled = value;
                    });
                    // TODO: Save setting via API
                  },
                  activeColor: AppColors.accentPurple,
                ),
              ],
            ),
          ),
          if (_autoBackupEnabled) ...[
            SizedBox(height: AppSpacing.spacingMD),
            SectionHeader(
              title: 'Backup Frequency',
              icon: Icons.repeat,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildFrequencyOption(
              'Daily',
              'daily',
              Icons.today,
              textColor,
              secondaryTextColor,
              surfaceColor,
              borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildFrequencyOption(
              'Weekly',
              'weekly',
              Icons.calendar_view_week,
              textColor,
              secondaryTextColor,
              surfaceColor,
              borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildFrequencyOption(
              'Monthly',
              'monthly',
              Icons.calendar_month,
              textColor,
              secondaryTextColor,
              surfaceColor,
              borderColor,
            ),
          ],
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Restore
          SectionHeader(
            title: 'Restore Backup',
            icon: Icons.restore,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.warningYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: AppColors.warningYellow.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
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
                  icon: Icons.restore,
                  backgroundColor: AppColors.warningYellow,
                ),
              ],
            ),
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // What's backed up
          SectionHeader(
            title: 'What\'s Backed Up',
            icon: Icons.info,
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
    IconData icon,
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
          color: isSelected
              ? AppColors.accentPurple
              : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _backupFrequency = value;
          });
          // TODO: Save setting via API
        },
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.accentPurple
                    : secondaryTextColor,
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
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
          Icon(
            Icons.check,
            size: 16,
            color: AppColors.onlineGreen,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Text(
            text,
            style: AppTypography.body.copyWith(color: textColor),
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
