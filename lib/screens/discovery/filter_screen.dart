// Screen: FilterScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_page_header.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/discovery/filter_widgets.dart';
import '../../features/discover/data/models/discovery_filter_mapper.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../../features/reference_data/data/models/reference_item.dart';
import '../../features/reference_data/providers/reference_data_providers.dart';
import '../../shared/utils/plan_guard.dart';
import '../../routes/app_router.dart';

/// Discovery filters — basic for all users, advanced for premium.
class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key, this.initialFilters});

  /// Stored API-format filters from [DiscoveryPage].
  final Map<String, dynamic>? initialFilters;

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late RangeValues _ageRange;
  late double _maxDistance;
  late List<int> _selectedGenderIds;
  late bool _showVerifiedOnly;
  late bool _showOnlineOnly;
  late bool _showPremiumOnly;
  late List<int> _interestIds;
  late List<int> _jobIds;
  late List<int> _educationIds;
  late List<int> _languageIds;
  late List<int> _musicGenreIds;
  late List<int> _relationGoalIds;
  bool? _matchSmoke;
  bool? _matchDrink;
  bool? _matchGym;
  String _country = '';
  String _city = '';

  static final String _iconCake = AppIcons.getIconOutline('cake');
  static final String _iconLocation = AppIcons.getIconOutline('location');
  static final String _iconPeople = AppIcons.getIconOutline('people');
  static final String _iconFilter = AppIcons.getIconOutline('filter');
  static final String _iconHeart = AppIcons.getIconOutline('heart');
  static final String _iconBriefcase = AppIcons.getIconOutline('briefcase');
  static final String _iconBook = AppIcons.getIconOutline('book');
  static final String _iconGlobal = AppIcons.getIconOutline('global');
  static final String _iconMusic = AppIcons.getIconOutline('music');

  @override
  void initState() {
    super.initState();
    final seed = DiscoveryFilterMapper.toUiSeed(widget.initialFilters);
    _ageRange = seed['ageRange'] as RangeValues;
    _maxDistance = seed['maxDistance'] as double;
    _selectedGenderIds = List<int>.from(seed['genderIds'] as List<int>);
    _showVerifiedOnly = seed['verifiedOnly'] as bool;
    _showOnlineOnly = seed['onlineOnly'] as bool;
    _showPremiumOnly = seed['premiumOnly'] as bool;
    _interestIds = List<int>.from(seed['interestIds'] as List<int>);
    _jobIds = List<int>.from(seed['jobIds'] as List<int>);
    _educationIds = List<int>.from(seed['educationIds'] as List<int>);
    _languageIds = List<int>.from(seed['languageIds'] as List<int>);
    _musicGenreIds = List<int>.from(seed['musicGenreIds'] as List<int>);
    _relationGoalIds = List<int>.from(seed['relationGoalIds'] as List<int>);
    _matchSmoke = seed['matchSmoke'] as bool?;
    _matchDrink = seed['matchDrink'] as bool?;
    _matchGym = seed['matchGym'] as bool?;
    _country = seed['country'] as String;
    _city = seed['city'] as String;
  }

  bool get _isPremium =>
      ref.watch(planLimitsProvider).valueOrNull?.features.advancedFilters ??
      false;

  void _applyFilters() {
    final uiResult = <String, dynamic>{
      'ageRange': _ageRange,
      'maxDistance': _maxDistance,
      'genderIds': _selectedGenderIds,
      'verifiedOnly': _showVerifiedOnly,
      'onlineOnly': _showOnlineOnly,
      'premiumOnly': _showPremiumOnly,
      'interestIds': _interestIds,
      'jobIds': _jobIds,
      'educationIds': _educationIds,
      'languageIds': _languageIds,
      'musicGenreIds': _musicGenreIds,
      'relationGoalIds': _relationGoalIds,
      if (_matchSmoke != null) 'matchSmoke': _matchSmoke,
      if (_matchDrink != null) 'matchDrink': _matchDrink,
      if (_matchGym != null) 'matchGym': _matchGym,
      'country': _country,
      'city': _city,
    };

    final apiFilters = DiscoveryFilterMapper.fromUiResult(
      uiResult,
      isPremium: _isPremium,
    );

    Navigator.of(context).pop(apiFilters);
  }

  void _resetFilters() {
    setState(() {
      final defaults = DiscoveryFilterMapper.toUiSeed(null);
      _ageRange = defaults['ageRange'] as RangeValues;
      _maxDistance = defaults['maxDistance'] as double;
      _selectedGenderIds = [];
      _showVerifiedOnly = false;
      _showOnlineOnly = false;
      _showPremiumOnly = false;
      _interestIds = [];
      _jobIds = [];
      _educationIds = [];
      _languageIds = [];
      _musicGenreIds = [];
      _relationGoalIds = [];
      _matchSmoke = null;
      _matchDrink = null;
      _matchGym = null;
      _country = '';
      _city = '';
    });
  }

  void _toggleGender(int genderId) {
    setState(() {
      if (_selectedGenderIds.contains(genderId)) {
        _selectedGenderIds.remove(genderId);
      } else {
        _selectedGenderIds.add(genderId);
      }
    });
  }

  Future<void> _openUpgrade() async {
    final target = Uri(
      path: AppRoutes.featureLocked,
      queryParameters: {
        'title': 'Advanced filters',
        'desc':
            'Upgrade to unlock advanced filters and find better matches faster.',
        'minTier': 'silder',
      },
    ).toString();
    await context.push(target);
  }

  Future<void> _onPremiumToggle(bool value) async {
    if (!value) {
      setState(() => _showPremiumOnly = false);
      return;
    }
    if (_isPremium) {
      setState(() => _showPremiumOnly = true);
      return;
    }
    final guard = PlanGuard(ref.read(planLimitsServiceProvider));
    final result = await guard.canUseAdvancedFilters();
    if (!mounted) return;
    if (!result.isAllowed) {
      await _openUpgrade();
      return;
    }
    setState(() => _showPremiumOnly = true);
  }

  List<({int id, String label})> _mapOptions(List<ReferenceItem> items) {
    return items
        .map((item) => (id: item.id, label: item.title))
        .toList(growable: false);
  }

  Widget _lifestyleToggle({
    required String title,
    required String subtitle,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const FilterProBadge(),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                  ),
                ),
              ],
            ),
          ),
          SegmentedButton<bool?>(
            segments: const [
              ButtonSegment<bool?>(
                value: null,
                label: Text('Any'),
              ),
              ButtonSegment<bool?>(
                value: true,
                label: Text('Yes'),
              ),
              ButtonSegment<bool?>(
                value: false,
                label: Text('No'),
              ),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ],
      ),
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
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final gendersAsync = ref.watch(gendersProvider);
    final interestsAsync = ref.watch(interestsProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final educationAsync = ref.watch(educationLevelsProvider);
    final languagesAsync = ref.watch(languagesProvider);
    final musicAsync = ref.watch(musicGenresProvider);
    final goalsAsync = ref.watch(relationshipGoalsProvider);
    final countriesAsync = ref.watch(countriesProvider);

    return AppPageScaffold(
      title: 'Filters',
      showBackButton: true,
      backgroundColor: backgroundColor,
      action: TextButton(
        onPressed: _resetFilters,
        child: Text(
          'Reset',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppPageHeader.horizontalPadding,
                AppSpacing.spacingMD,
                AppPageHeader.horizontalPadding,
                AppSpacing.spacingLG,
              ),
              children: [
                FilterSectionHeader(iconPath: _iconCake, title: 'Age Range'),
                SizedBox(height: AppSpacing.spacingLG),
                FilterSliderTheme(
                  child: RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 100,
                    divisions: 82,
                    onChanged: (values) => setState(() => _ageRange = values),
                  ),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_ageRange.start.round()}',
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_ageRange.end.round()}',
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const FilterSectionDivider(),
                FilterSectionHeader(
                  iconPath: _iconLocation,
                  title: 'Maximum Distance',
                ),
                SizedBox(height: AppSpacing.spacingLG),
                FilterSliderTheme(
                  child: Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 200,
                    divisions: 199,
                    onChanged: (value) => setState(() => _maxDistance = value),
                  ),
                ),
                FilterValuePill(label: '${_maxDistance.round()} km'),
                const FilterSectionDivider(),
                FilterSectionHeader(iconPath: _iconPeople, title: 'Show Me'),
                SizedBox(height: AppSpacing.spacingMD),
                gendersAsync.when(
                  data: (genders) {
                    if (genders.isEmpty) {
                      return Text(
                        'Gender options unavailable',
                        style: AppTypography.caption.copyWith(
                          color: secondaryColor,
                        ),
                      );
                    }
                    return Wrap(
                      spacing: AppSpacing.spacingSM,
                      runSpacing: AppSpacing.spacingSM,
                      children: [
                        FilterGenderChip(
                          label: 'All',
                          isSelected: _selectedGenderIds.isEmpty,
                          onTap: () => setState(() => _selectedGenderIds = []),
                        ),
                        ...genders.map(
                          (gender) => FilterGenderChip(
                            label: gender.title,
                            isSelected:
                                _selectedGenderIds.contains(gender.id),
                            onTap: () => _toggleGender(gender.id),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.spacingMD),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Could not load gender options',
                    style: AppTypography.caption.copyWith(color: secondaryColor),
                  ),
                ),
                const FilterSectionDivider(),
                Row(
                  children: [
                    Expanded(
                      child: FilterSectionHeader(
                        iconPath: _iconFilter,
                        title: 'Advanced Filters',
                      ),
                    ),
                    if (!_isPremium) const FilterProBadge(),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingSM),
                FilterPremiumGate(
                  isPremium: _isPremium,
                  onUpgrade: _openUpgrade,
                  child: Column(
                    children: [
                      FilterToggleRow(
                        iconPath: AppIcons.verify,
                        title: 'Verified Only',
                        subtitle: 'Show only verified profiles',
                        value: _showVerifiedOnly,
                        onChanged: (v) =>
                            setState(() => _showVerifiedOnly = v),
                        trailing: const FilterProBadge(),
                      ),
                      FilterToggleRow(
                        iconPath: AppIcons.online,
                        title: 'Online Only',
                        subtitle: 'Show only online users',
                        value: _showOnlineOnly,
                        onChanged: (v) => setState(() => _showOnlineOnly = v),
                        trailing: const FilterProBadge(),
                      ),
                      FilterToggleRow(
                        iconPath: AppIcons.crown,
                        title: 'Premium Only',
                        subtitle: 'Show only premium members',
                        value: _showPremiumOnly,
                        onChanged: _onPremiumToggle,
                        trailing: const FilterProBadge(),
                      ),
                      const FilterSectionDivider(),
                      interestsAsync.when(
                        data: (items) => FilterMultiSelectSection(
                          title: 'Interests',
                          iconPath: _iconHeart,
                          options: _mapOptions(items),
                          selectedIds: _interestIds,
                          enabled: _isPremium,
                          onChanged: (ids) =>
                              setState(() => _interestIds = ids),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      goalsAsync.when(
                        data: (items) => FilterMultiSelectSection(
                          title: 'Relationship Goals',
                          iconPath: _iconHeart,
                          options: _mapOptions(items),
                          selectedIds: _relationGoalIds,
                          enabled: _isPremium,
                          onChanged: (ids) =>
                              setState(() => _relationGoalIds = ids),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      jobsAsync.when(
                        data: (items) => FilterMultiSelectSection(
                          title: 'Profession',
                          iconPath: _iconBriefcase,
                          options: _mapOptions(items),
                          selectedIds: _jobIds,
                          enabled: _isPremium,
                          onChanged: (ids) => setState(() => _jobIds = ids),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      educationAsync.when(
                        data: (items) => FilterMultiSelectSection(
                          title: 'Education',
                          iconPath: _iconBook,
                          options: _mapOptions(items),
                          selectedIds: _educationIds,
                          enabled: _isPremium,
                          onChanged: (ids) =>
                              setState(() => _educationIds = ids),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      languagesAsync.when(
                        data: (items) => FilterMultiSelectSection(
                          title: 'Languages',
                          iconPath: _iconGlobal,
                          options: _mapOptions(items),
                          selectedIds: _languageIds,
                          enabled: _isPremium,
                          onChanged: (ids) =>
                              setState(() => _languageIds = ids),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      musicAsync.when(
                        data: (items) => FilterMultiSelectSection(
                          title: 'Music Taste',
                          iconPath: _iconMusic,
                          options: _mapOptions(items),
                          selectedIds: _musicGenreIds,
                          enabled: _isPremium,
                          onChanged: (ids) =>
                              setState(() => _musicGenreIds = ids),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const FilterSectionDivider(),
                      FilterSectionHeader(
                        iconPath: _iconFilter,
                        title: 'Lifestyle Match',
                      ),
                      _lifestyleToggle(
                        title: 'Smoking',
                        subtitle: 'Match smoking preference',
                        value: _matchSmoke,
                        onChanged: (v) => setState(() => _matchSmoke = v),
                      ),
                      _lifestyleToggle(
                        title: 'Drinking',
                        subtitle: 'Match drinking preference',
                        value: _matchDrink,
                        onChanged: (v) => setState(() => _matchDrink = v),
                      ),
                      _lifestyleToggle(
                        title: 'Fitness / Gym',
                        subtitle: 'Match gym preference',
                        value: _matchGym,
                        onChanged: (v) => setState(() => _matchGym = v),
                      ),
                      const FilterSectionDivider(),
                      FilterSectionHeader(
                        iconPath: _iconLocation,
                        title: 'Location',
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      countriesAsync.when(
                        data: (countries) {
                          if (countries.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Wrap(
                            spacing: AppSpacing.spacingSM,
                            runSpacing: AppSpacing.spacingSM,
                            children: [
                              FilterGenderChip(
                                label: 'Any country',
                                isSelected: _country.isEmpty,
                                onTap: () => setState(() {
                                  _country = '';
                                  _city = '';
                                }),
                              ),
                              ...countries.take(12).map(
                                    (country) => FilterGenderChip(
                                      label: country.title,
                                      isSelected: _country == country.title,
                                      onTap: () => setState(() {
                                        _country = country.title;
                                        _city = '';
                                      }),
                                    ),
                                  ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Tip: widen age or distance if you see fewer profiles nearby.',
                  style: AppTypography.caption.copyWith(color: secondaryColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.borderSubtleDark
                      : AppColors.borderSubtleLight,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.spacingLG,
                  AppSpacing.spacingMD,
                  AppSpacing.spacingLG,
                  AppSpacing.spacingMD,
                ),
                child: GradientButton(
                  text: 'Apply Filters',
                  iconPath: AppIcons.getIconOutline('filter-tick'),
                  onPressed: _applyFilters,
                  isFullWidth: true,
                  height: 52,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
