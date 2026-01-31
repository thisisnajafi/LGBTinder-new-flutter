// Screen: MatchingPreferencesScreen (Task 4 — Matching/Discovery preferences)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../widgets/common/section_header.dart';
import '../../data/models/matching_preferences.dart';
import '../../providers/settings_provider.dart';

/// Matching/Discovery preferences screen — age range, distance, discovery visibility
class MatchingPreferencesScreen extends ConsumerStatefulWidget {
  const MatchingPreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MatchingPreferencesScreen> createState() => _MatchingPreferencesScreenState();
}

class _MatchingPreferencesScreenState extends ConsumerState<MatchingPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _initialLoadDone = false;
  String? _error;
  late int _ageMin;
  late int _ageMax;
  late double _distance;
  late String _discoveryVisibility;

  @override
  void initState() {
    super.initState();
    _ageMin = 18;
    _ageMax = 100;
    _distance = 50;
    _discoveryVisibility = 'everyone';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      final prefs = await service.getPreferences();
      if (mounted) {
        setState(() {
          _ageMin = prefs.ageMin;
          _ageMax = prefs.ageMax;
          _distance = prefs.distance;
          _discoveryVisibility = prefs.discoveryVisibility;
          _loading = false;
          _initialLoadDone = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      final prefs = MatchingPreferences(
        ageMin: _ageMin,
        ageMax: _ageMax,
        distance: _distance,
        discoveryVisibility: _discoveryVisibility,
      );
      await service.updatePreferences(prefs);
      ref.invalidate(matchingPreferencesProvider);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discovery preferences saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
        });
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

    if (!_initialLoadDone) {
      _initialLoadDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Discovery preferences',
        showBackButton: true,
      ),
      body: _loading && _error == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.accentRed, size: 24),
                        SizedBox(width: AppSpacing.spacingSM),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTypography.body.copyWith(color: AppColors.accentRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                ],
                SectionHeader(
                  title: 'Age range',
                  iconPath: AppIcons.userOutline,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RangeSlider(
                        values: RangeValues(_ageMin.toDouble(), _ageMax.toDouble()),
                        min: 18,
                        max: 100,
                        divisions: 82,
                        activeColor: AppColors.accentPurple,
                        onChanged: _loading || _saving
                            ? null
                            : (v) {
                                setState(() {
                                  _ageMin = v.start.round().clamp(18, _ageMax);
                                  _ageMax = v.end.round().clamp(_ageMin, 100);
                                });
                              },
                      ),
                      Text(
                        '${_ageMin} – ${_ageMax} years',
                        style: AppTypography.body.copyWith(color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingLG),
                SectionHeader(
                  title: 'Distance',
                  iconPath: AppIcons.discover,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: _distance.clamp(1.0, 500.0),
                        min: 1,
                        max: 500,
                        divisions: 499,
                        activeColor: AppColors.accentPurple,
                        onChanged: _loading || _saving
                            ? null
                            : (v) => setState(() => _distance = v.roundToDouble()),
                      ),
                      Text(
                        'Up to ${_distance.round()} km',
                        style: AppTypography.body.copyWith(color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingLG),
                SectionHeader(
                  title: 'Discovery visibility',
                  iconPath: AppIcons.lockOutline,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Who can see your profile in discovery',
                        style: AppTypography.caption.copyWith(color: secondaryTextColor),
                      ),
                      SizedBox(height: AppSpacing.spacingSM),
                      ...['everyone', 'people_i_like', 'hidden'].map((value) {
                        final label = value == 'everyone'
                            ? 'Everyone'
                            : value == 'people_i_like'
                                ? 'Only people I\'ve liked'
                                : 'Hidden from discovery';
                        final selected = _discoveryVisibility == value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.spacingXS),
                          child: Material(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            child: InkWell(
                              onTap: _loading || _saving
                                  ? null
                                  : () => setState(() => _discoveryVisibility = value),
                              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingMD, vertical: AppSpacing.spacingSM),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: value,
                                      groupValue: _discoveryVisibility,
                                      onChanged: _loading || _saving
                                          ? null
                                          : (v) => setState(() => _discoveryVisibility = v ?? value),
                                      activeColor: AppColors.accentPurple,
                                    ),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: AppTypography.body.copyWith(color: textColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading || _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
    );
  }
}
