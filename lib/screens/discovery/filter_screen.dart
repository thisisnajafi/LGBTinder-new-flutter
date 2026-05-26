// Screen: FilterScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_page_header.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/discovery/filter_widgets.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../../shared/utils/plan_guard.dart';
import '../../routes/app_router.dart';

/// Discovery filters — age, distance, gender, and advanced options.
class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  RangeValues _ageRange = const RangeValues(18, 35);
  double _maxDistance = 50;
  List<String> _selectedGenders = ['All'];
  bool _showVerifiedOnly = false;
  bool _showOnlineOnly = false;
  bool _showPremiumOnly = false;

  static const List<String> _availableGenders = [
    'All',
    'Male',
    'Female',
    'Non-binary',
    'Other',
  ];

  static final String _iconCake = AppIcons.getIconOutline('cake');
  static final String _iconLocation = AppIcons.getIconOutline('location');
  static final String _iconPeople = AppIcons.getIconOutline('people');
  static final String _iconFilter = AppIcons.getIconOutline('filter');

  void _applyFilters() {
    Navigator.of(context).pop({
      'ageRange': _ageRange,
      'maxDistance': _maxDistance,
      'genders': _selectedGenders,
      'verifiedOnly': _showVerifiedOnly,
      'onlineOnly': _showOnlineOnly,
      'premiumOnly': _showPremiumOnly,
    });
  }

  void _resetFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 35);
      _maxDistance = 50;
      _selectedGenders = ['All'];
      _showVerifiedOnly = false;
      _showOnlineOnly = false;
      _showPremiumOnly = false;
    });
  }

  void _toggleGender(String gender) {
    setState(() {
      if (gender == 'All') {
        _selectedGenders = ['All'];
        return;
      }
      _selectedGenders.remove('All');
      if (_selectedGenders.contains(gender)) {
        _selectedGenders.remove(gender);
      } else {
        _selectedGenders.add(gender);
      }
      if (_selectedGenders.isEmpty) {
        _selectedGenders = ['All'];
      }
    });
  }

  Future<void> _onPremiumToggle(bool value) async {
    if (!value) {
      setState(() => _showPremiumOnly = false);
      return;
    }
    final service = ref.read(planLimitsServiceProvider);
    final guard = PlanGuard(service);
    final result = await guard.canUseAdvancedFilters();
    if (!mounted) return;
    if (!result.isAllowed) {
      final target = Uri(
        path: AppRoutes.featureLocked,
        queryParameters: {
          'title': 'Advanced filters',
          'desc': 'Upgrade to unlock advanced filters and find better matches faster.',
          'minTier': 'silder',
        },
      ).toString();
      context.push(target);
      return;
    }
    setState(() => _showPremiumOnly = true);
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
                // —— Age range ——
                FilterSectionHeader(
                  iconPath: _iconCake,
                  title: 'Age Range',
                ),
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

                // —— Distance ——
                FilterSectionHeader(
                  iconPath: _iconLocation,
                  title: 'Maximum Distance',
                ),
                SizedBox(height: AppSpacing.spacingLG),
                FilterSliderTheme(
                  child: Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (value) => setState(() => _maxDistance = value),
                  ),
                ),
                FilterValuePill(label: '${_maxDistance.round()} km'),
                const FilterSectionDivider(),

                // —— Show me ——
                FilterSectionHeader(
                  iconPath: _iconPeople,
                  title: 'Show Me',
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Wrap(
                  spacing: AppSpacing.spacingSM,
                  runSpacing: AppSpacing.spacingSM,
                  children: _availableGenders.map((gender) {
                    return FilterGenderChip(
                      label: gender,
                      isSelected: _selectedGenders.contains(gender),
                      onTap: () => _toggleGender(gender),
                    );
                  }).toList(),
                ),
                const FilterSectionDivider(),

                // —— Additional filters ——
                FilterSectionHeader(
                  iconPath: _iconFilter,
                  title: 'Additional Filters',
                ),
                SizedBox(height: AppSpacing.spacingSM),
                FilterToggleRow(
                  iconPath: AppIcons.verify,
                  title: 'Verified Only',
                  subtitle: 'Show only verified profiles',
                  value: _showVerifiedOnly,
                  onChanged: (v) => setState(() => _showVerifiedOnly = v),
                ),
                FilterToggleRow(
                  iconPath: AppIcons.online,
                  title: 'Online Only',
                  subtitle: 'Show only online users',
                  value: _showOnlineOnly,
                  onChanged: (v) => setState(() => _showOnlineOnly = v),
                ),
                FilterToggleRow(
                  iconPath: AppIcons.crown,
                  title: 'Premium Only',
                  subtitle: 'Show only premium members',
                  value: _showPremiumOnly,
                  onChanged: _onPremiumToggle,
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingSM,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.radiusXS),
                    ),
                    child: Text(
                      'PRO',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
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
