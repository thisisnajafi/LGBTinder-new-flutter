// Screen: MatchingPreferencesScreen (Task 4 — Matching/Discovery preferences)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../data/models/matching_preferences.dart';
import '../../providers/settings_provider.dart';
import '../../../../core/cache/cache_invalidator.dart';
import '../../../discover/providers/discover_cache_provider.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      // Load age from GET preferences/age (backend preferences/age endpoint)
      int? loadedAgeMin;
      int? loadedAgeMax;
      try {
        final ageData = await service.getAgePreferences();
        final min = ageData['min_age'];
        final max = ageData['max_age'];
        if (min != null) loadedAgeMin = min is int ? min : int.tryParse(min.toString());
        if (max != null) loadedAgeMax = max is int ? max : int.tryParse(max.toString());
      } catch (e) { AppLogger.warning('Silently caught exception', tag: 'matching_preferences_screen', error: e); }
      // Load full preferences (distance, visibility; fallback for age if preferences/age had no data)
      final prefs = await service.getPreferences();
      if (kDebugMode) {
        debugPrint('[DISCOVERY_PREFS] loaded: ageMin=${loadedAgeMin ?? prefs.ageMin} ageMax=${loadedAgeMax ?? prefs.ageMax} distance=${prefs.distance} visibility=${prefs.discoveryVisibility}');
      }
      if (mounted) {
        setState(() {
          _ageMin = loadedAgeMin ?? prefs.ageMin;
          _ageMax = loadedAgeMax ?? prefs.ageMax;
          _distance = prefs.distance;
          _discoveryVisibility = prefs.discoveryVisibility;
          _loading = false;
          _initialLoadDone = true;
        });
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[DISCOVERY_PREFS] _load error: $e');
        debugPrint('[DISCOVERY_PREFS] stack: $stack');
      }
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
      // Save age via PUT preferences/age (backend preferences/age endpoint)
      await service.updateAgePreferences(minAge: _ageMin, maxAge: _ageMax);
      // Save full preferences (age + distance + visibility) via PUT preferences/matching
      final prefs = MatchingPreferences(
        ageMin: _ageMin,
        ageMax: _ageMax,
        distance: _distance,
        discoveryVisibility: _discoveryVisibility,
      );
      final updated = await service.updatePreferences(prefs);
      ref.invalidate(matchingPreferencesProvider);
      await ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      await ref.read(discoverCacheProvider.notifier).clearAndRefresh();
      if (mounted) {
        setState(() {
          _saving = false;
          _ageMin = updated.ageMin;
          _ageMax = updated.ageMax;
          _distance = updated.distance;
          _discoveryVisibility = updated.discoveryVisibility;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discovery preferences saved')),
        );
      }
      if (kDebugMode) {
        debugPrint('[DISCOVERY_PREFS] saved: ageMin=${updated.ageMin} ageMax=${updated.ageMax} distance=${updated.distance}');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[DISCOVERY_PREFS] _save error: $e');
        debugPrint('[DISCOVERY_PREFS] stack: $stack');
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
        });
      }
    }
  }

  Future<void> _resetAgeRange() async {
    if (_loading || _saving) return;
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      await service.resetAgePreferences();
      await ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      await ref.read(discoverCacheProvider.notifier).clearAndRefresh();
      if (mounted) {
        setState(() {
          _ageMin = 18;
          _ageMax = 100;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Age range reset to 18–100')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reset: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return AppSettingsDetailScaffold(
      title: 'Discovery preferences',
      subtitle: 'Age, distance, and who can see you',
      body: _loading && _error == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: AppSettingsDetailList(
                children: [
                  if (_error != null) ...[
                    PremiumSettingsGroup(
                      title: 'Could not load',
                      children: [
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.feedbackError,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacingXL),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingLG,
                    ),
                    child: PremiumFilterSection(
                      iconPath: AppIcons.userOutline,
                      title: 'Age range',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RangeSlider(
                            values: RangeValues(
                              _ageMin.toDouble(),
                              _ageMax.toDouble(),
                            ),
                            min: 18,
                            max: 100,
                            divisions: 82,
                            activeColor: AppColors.accentPink,
                            onChanged: _loading || _saving
                                ? null
                                : (v) {
                                    setState(() {
                                      _ageMin =
                                          v.start.round().clamp(18, _ageMax);
                                      _ageMax =
                                          v.end.round().clamp(_ageMin, 100);
                                    });
                                  },
                          ),
                          Text(
                            '$_ageMin – $_ageMax years',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                          if (!_loading && !_saving)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _resetAgeRange,
                                child: Text(
                                  'Reset age range',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.accentViolet,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingLG,
                    ),
                    child: PremiumFilterSection(
                      iconPath: AppIcons.discover,
                      title: 'Distance',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Slider(
                            value: _distance.clamp(1.0, 500.0),
                            min: 1,
                            max: 500,
                            divisions: 499,
                            activeColor: AppColors.accentPink,
                            onChanged: _loading || _saving
                                ? null
                                : (v) => setState(
                                      () => _distance = v.roundToDouble(),
                                    ),
                          ),
                          Text(
                            'Up to ${_distance.round()} km',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PremiumSettingsGroup(
                    title: 'Discovery visibility',
                    subtitle: 'Who can see your profile in discovery',
                    children: [
                      for (final entry in const [
                        ('everyone', 'Everyone'),
                        ('people_i_like', 'Only people I\'ve liked'),
                        ('hidden', 'Hidden from discovery'),
                      ])
                        PremiumSoundOptionTile(
                          label: entry.$2,
                          isSelected: _discoveryVisibility == entry.$1,
                          onSelect: _loading || _saving
                              ? null
                              : () => setState(
                                    () => _discoveryVisibility = entry.$1,
                                  ),
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
                      text: 'Save preferences',
                      onPressed: _loading || _saving ? () {} : _save,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
