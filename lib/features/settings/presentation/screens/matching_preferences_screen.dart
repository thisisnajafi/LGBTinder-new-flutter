// Screen: MatchingPreferencesScreen (Task 4 — Matching/Discovery preferences)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../discover/providers/discover_cache_provider.dart';
import '../../data/models/matching_preferences.dart';
import '../../providers/settings_provider.dart';
import '../../utils/matching_preferences_draft.dart';

/// Matching/Discovery preferences screen — age range, distance, discovery visibility
class MatchingPreferencesScreen extends ConsumerStatefulWidget {
  const MatchingPreferencesScreen({super.key});

  @override
  ConsumerState<MatchingPreferencesScreen> createState() =>
      _MatchingPreferencesScreenState();
}

class _MatchingPreferencesScreenState
    extends ConsumerState<MatchingPreferencesScreen> {
  final _draft = MatchingPreferencesDraft();
  final _loading = ValueNotifier<bool>(true);
  final _saving = ValueNotifier<bool>(false);
  final _hasLoaded = ValueNotifier<bool>(false);
  final _error = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _draft.dispose();
    _loading.dispose();
    _saving.dispose();
    _hasLoaded.dispose();
    _error.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_hasLoaded.value) _loading.value = true;
    _error.value = null;
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      int? loadedAgeMin;
      int? loadedAgeMax;
      try {
        final ageData = await service.getAgePreferences();
        final min = ageData['min_age'];
        final max = ageData['max_age'];
        if (min != null) {
          loadedAgeMin = min is int ? min : int.tryParse(min.toString());
        }
        if (max != null) {
          loadedAgeMax = max is int ? max : int.tryParse(max.toString());
        }
      } catch (e) {
        AppLogger.warning(
          'Silently caught exception',
          tag: 'matching_preferences_screen',
          error: e,
        );
      }
      final prefs = await service.getPreferences();
      if (!mounted) return;
      _draft.apply(
        MatchingPreferences(
          ageMin: loadedAgeMin ?? prefs.ageMin,
          ageMax: loadedAgeMax ?? prefs.ageMax,
          distance: prefs.distance,
          discoveryVisibility: prefs.discoveryVisibility,
        ),
      );
      AppLogger.debug(
        'loaded: ageMin=${_draft.ageRange.value.start.round()} '
        'ageMax=${_draft.ageRange.value.end.round()} '
        'distance=${_draft.distance.value} '
        'visibility=${_draft.visibility.value}',
        tag: 'DISCOVERY_PREFS',
      );
      _hasLoaded.value = true;
      _loading.value = false;
    } catch (e, stack) {
      AppLogger.warning(
        '_load error: $e',
        tag: 'DISCOVERY_PREFS',
        error: e,
      );
      AppLogger.debug('$stack', tag: 'DISCOVERY_PREFS');
      if (!mounted) return;
      _error.value = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
      _loading.value = false;
    }
  }

  Future<void> _save() async {
    if (_loading.value || _saving.value) return;
    _saving.value = true;
    _error.value = null;
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      final prefs = _draft.toPreferences();
      await service.updateAgePreferences(
        minAge: prefs.ageMin,
        maxAge: prefs.ageMax,
      );
      final updated = await service.updatePreferences(prefs);
      ref.invalidate(matchingPreferencesProvider);
      await ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      await ref.read(discoverCacheProvider.notifier).clearAndRefresh();
      if (!mounted) return;
      _draft.apply(updated);
      _saving.value = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discovery preferences saved')),
      );
      AppLogger.debug(
        'saved: ageMin=${updated.ageMin} ageMax=${updated.ageMax} '
        'distance=${updated.distance}',
        tag: 'DISCOVERY_PREFS',
      );
    } catch (e, stack) {
      AppLogger.warning(
        '_save error: $e',
        tag: 'DISCOVERY_PREFS',
        error: e,
      );
      AppLogger.debug('$stack', tag: 'DISCOVERY_PREFS');
      if (!mounted) return;
      _saving.value = false;
      _error.value = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
    }
  }

  Future<void> _resetAgeRange() async {
    if (_loading.value || _saving.value) return;
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      await service.resetAgePreferences();
      await ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      await ref.read(discoverCacheProvider.notifier).clearAndRefresh();
      if (!mounted) return;
      _draft.resetAgeRange();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age range reset to 18–100')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not reset: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Discovery preferences',
      subtitle: 'Age, distance, and who can see you',
      body: ValueListenableBuilder<bool>(
        valueListenable: _loading,
        builder: (context, loading, _) {
          if (loading && !_hasLoaded.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return PremiumRefreshIndicator(
            onRefresh: _load,
            child: AppSettingsDetailList(
              children: [
                _MatchingErrorBanner(error: _error),
                _MatchingAgeSection(
                  draft: _draft,
                  loading: _loading,
                  saving: _saving,
                  onReset: _resetAgeRange,
                ),
                _MatchingDistanceSection(
                  draft: _draft,
                  loading: _loading,
                  saving: _saving,
                ),
                _MatchingVisibilitySection(
                  draft: _draft,
                  loading: _loading,
                  saving: _saving,
                ),
                _MatchingSaveButton(
                  loading: _loading,
                  saving: _saving,
                  onSave: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MatchingErrorBanner extends StatelessWidget {
  const _MatchingErrorBanner({required this.error});

  final ValueNotifier<String?> error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: error,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();
        return Column(
          children: [
            PremiumSettingsGroup(
              title: 'Could not load',
              children: [
                AppText(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.feedbackError,
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
          ],
        );
      },
    );
  }
}

class _MatchingAgeSection extends StatelessWidget {
  const _MatchingAgeSection({
    required this.draft,
    required this.loading,
    required this.saving,
    required this.onReset,
  });

  final MatchingPreferencesDraft draft;
  final ValueNotifier<bool> loading;
  final ValueNotifier<bool> saving;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      child: PremiumFilterSection(
        iconPath: AppIcons.userOutline,
        title: 'Age range',
        child: ValueListenableBuilder<bool>(
          valueListenable: loading,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: saving,
              builder: (context, isSaving, _) {
                final locked = isLoading || isSaving;
                return ValueListenableBuilder<RangeValues>(
                  valueListenable: draft.ageRange,
                  builder: (context, range, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RangeSlider(
                          values: range,
                          min: kMatchingAgeMin.toDouble(),
                          max: kMatchingAgeMax.toDouble(),
                          divisions: kMatchingAgeMax - kMatchingAgeMin,
                          activeColor: AppColors.accentPink,
                          onChanged: locked
                              ? null
                              : (v) => draft.ageRange.value =
                                  clampMatchingAgeRange(v),
                        ),
                        AppText(
                          '${range.start.round()} – ${range.end.round()} years',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                        ),
                        if (!locked)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: onReset,
                              child: AppText(
                                'Reset age range',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.accentViolet,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MatchingDistanceSection extends StatelessWidget {
  const _MatchingDistanceSection({
    required this.draft,
    required this.loading,
    required this.saving,
  });

  final MatchingPreferencesDraft draft;
  final ValueNotifier<bool> loading;
  final ValueNotifier<bool> saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      child: PremiumFilterSection(
        iconPath: AppIcons.discover,
        title: 'Distance',
        child: ValueListenableBuilder<bool>(
          valueListenable: loading,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: saving,
              builder: (context, isSaving, _) {
                final locked = isLoading || isSaving;
                return ValueListenableBuilder<double>(
                  valueListenable: draft.distance,
                  builder: (context, distance, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: distance.clamp(
                            kMatchingDistanceMin,
                            kMatchingDistanceMax,
                          ),
                          min: kMatchingDistanceMin,
                          max: kMatchingDistanceMax,
                          divisions: (kMatchingDistanceMax - kMatchingDistanceMin)
                              .round(),
                          activeColor: AppColors.accentPink,
                          onChanged: locked
                              ? null
                              : (v) => draft.distance.value =
                                  clampMatchingDistance(v),
                        ),
                        AppText(
                          'Up to ${distance.round()} km',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MatchingVisibilitySection extends StatelessWidget {
  const _MatchingVisibilitySection({
    required this.draft,
    required this.loading,
    required this.saving,
  });

  final MatchingPreferencesDraft draft;
  final ValueNotifier<bool> loading;
  final ValueNotifier<bool> saving;

  static const _options = [
    ('everyone', 'Everyone'),
    ('people_i_like', "Only people I've liked"),
    ('hidden', 'Hidden from discovery'),
  ];

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsGroup(
      title: 'Discovery visibility',
      subtitle: 'Who can see your profile in discovery',
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: loading,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: saving,
              builder: (context, isSaving, _) {
                final locked = isLoading || isSaving;
                return ValueListenableBuilder<String>(
                  valueListenable: draft.visibility,
                  builder: (context, selected, _) {
                    return Column(
                      children: [
                        for (final entry in _options)
                          PremiumSoundOptionTile(
                            label: entry.$2,
                            isSelected: selected == entry.$1,
                            onSelect: locked
                                ? null
                                : () => draft.visibility.value = entry.$1,
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _MatchingSaveButton extends StatelessWidget {
  const _MatchingSaveButton({
    required this.loading,
    required this.saving,
    required this.onSave,
  });

  final ValueNotifier<bool> loading;
  final ValueNotifier<bool> saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsivePadding.horizontal(context).copyWith(
        top: AppSpacing.spacingXL,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: loading,
        builder: (context, isLoading, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: saving,
            builder: (context, isSaving, _) {
              return GradientButton(
                text: 'Save preferences',
                onPressed: isLoading || isSaving ? null : onSave,
                isFullWidth: true,
              );
            },
          );
        },
      ),
    );
  }
}
