// Screen: CallSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/common/call_quota_display.dart';
import '../../features/calls/providers/call_provider.dart';
import '../../features/calls/data/models/call_settings.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';

/// Call settings screen - Configure call preferences
class CallSettingsScreen extends ConsumerStatefulWidget {
  const CallSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CallSettingsScreen> createState() => _CallSettingsScreenState();
}

class _CallSettingsScreenState extends ConsumerState<CallSettingsScreen> {
  bool _isLoading = false;
  CallSettings? _settings;

  // Form values
  bool _videoEnabled = true;
  bool _audioEnabled = true;
  bool _speakerEnabled = false;
  String? _ringtone;
  bool _autoAcceptCalls = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final callProviderInstance = ref.read(callProvider);
      final settings = await callProviderInstance.getCallSettings();

      setState(() {
        _settings = settings;
        _videoEnabled = settings.videoEnabled;
        _audioEnabled = settings.audioEnabled;
        _speakerEnabled = settings.speakerEnabled;
        _ringtone = settings.ringtone;
        _autoAcceptCalls = settings.autoAcceptCalls;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to load call settings',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load call settings: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final callProviderInstance = ref.read(callProvider);
      final updatedSettings = CallSettings(
        videoEnabled: _videoEnabled,
        audioEnabled: _audioEnabled,
        speakerEnabled: _speakerEnabled,
        ringtone: _ringtone,
        autoAcceptCalls: _autoAcceptCalls,
      );

      await callProviderInstance.updateCallSettings(updatedSettings);

      setState(() {
        _settings = updatedSettings;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Call settings saved successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to save call settings',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save call settings: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: 'Call Settings',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Video & Audio'),
                  SizedBox(height: AppSpacing.spacingMD),

                  // Video enabled
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enable Video',
                          style: AppTypography.bodyMedium.copyWith(color: textColor),
                        ),
                        Switch(
                          value: _videoEnabled,
                          onChanged: (value) {
                            setState(() {
                              _videoEnabled = value;
                            });
                          },
                          activeColor: AppColors.accentPurple,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),

                  // Audio enabled
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enable Audio',
                          style: AppTypography.bodyMedium.copyWith(color: textColor),
                        ),
                        Switch(
                          value: _audioEnabled,
                          onChanged: (value) {
                            setState(() {
                              _audioEnabled = value;
                            });
                          },
                          activeColor: AppColors.accentPurple,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),

                  // Speaker enabled
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Speaker Mode',
                          style: AppTypography.bodyMedium.copyWith(color: textColor),
                        ),
                        Switch(
                          value: _speakerEnabled,
                          onChanged: (value) {
                            setState(() {
                              _speakerEnabled = value;
                            });
                          },
                          activeColor: AppColors.accentPurple,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingLG),

                  SectionHeader(title: 'Call Behavior'),
                  SizedBox(height: AppSpacing.spacingMD),

                  // Auto accept calls
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto Accept Calls',
                                style: AppTypography.bodyMedium.copyWith(color: textColor),
                              ),
                              SizedBox(height: AppSpacing.spacingXS),
                              Text(
                                'Automatically accept incoming calls',
                                style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoAcceptCalls,
                          onChanged: (value) {
                            setState(() {
                              _autoAcceptCalls = value;
                            });
                          },
                          activeColor: AppColors.accentPurple,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingLG),

                  SectionHeader(title: 'Usage & Limits'),
                  SizedBox(height: AppSpacing.spacingMD),

                  // Call quota display
                  const CallQuotaDisplay(),
                  SizedBox(height: AppSpacing.spacingXL),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
                        ),
                      ),
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

