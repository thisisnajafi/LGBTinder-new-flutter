import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/passport_provider.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../features/payments/data/services/plan_limits_service.dart';
import '../../../../features/reference_data/data/models/reference_item.dart';
import '../../../../features/reference_data/providers/reference_data_providers.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/utils/plan_guard.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/common/reference_bottom_sheet_field.dart';
import '../../../../widgets/common/selection_bottom_sheet.dart';
import '../../../../widgets/profile/profile_wizard_layout.dart';

class _DurationOption {
  const _DurationOption(this.hours, this.label);

  final int hours;
  final String label;
}

const _durationOptions = <_DurationOption>[
  _DurationOption(24, '24 hours'),
  _DurationOption(48, '48 hours'),
  _DurationOption(72, '72 hours'),
  _DurationOption(168, '1 week'),
];

/// Premium passport — explore discover in another city temporarily.
class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> {
  int? _countryId;
  int? _cityId;
  int _durationHours = 24;
  bool _isSubmitting = false;
  bool _accessChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAccess());
  }

  Future<void> _checkAccess() async {
    final guard = PlanGuard(ref.read(planLimitsServiceProvider));
    final result = await guard.canUsePassport();
    if (!mounted) return;
    if (!result.isAllowed) {
      final target = Uri(
        path: AppRoutes.featureLocked,
        queryParameters: {
          'title': 'Passport',
          'desc': result.errorMessage ?? 'Passport is a Premium feature.',
          'minTier': 'golden',
        },
      ).toString();
      context.pop();
      await context.push(target);
      return;
    }
    setState(() => _accessChecked = true);
  }

  String? _selectedCityLabel(List<ReferenceItem> cities) {
    if (_cityId == null) return null;
    for (final city in cities) {
      if (city.id == _cityId) return city.title;
    }
    return null;
  }

  String get _durationLabel {
    for (final option in _durationOptions) {
      if (option.hours == _durationHours) return option.label;
    }
    return '$_durationHours hours';
  }

  Future<void> _pickDuration() async {
    if (_isSubmitting) return;
    final selected = _durationOptions.firstWhere(
      (option) => option.hours == _durationHours,
      orElse: () => _durationOptions.first,
    );
    final picked = await SelectionBottomSheet.showSingleSelect<_DurationOption>(
      context: context,
      title: 'Select duration',
      items: _durationOptions,
      getTitle: (option) => option.label,
      selectedItem: selected,
      searchable: false,
    );
    if (picked != null && mounted) {
      setState(() => _durationHours = picked.hours);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiError) return error.message;
    final text = error.toString();
    if (text.startsWith('ApiError(')) {
      final match = RegExp(r'message: ([^,}]+)').firstMatch(text);
      if (match != null) return match.group(1)!.trim();
    }
    return text;
  }

  Future<void> _activatePassport() async {
    if (_cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a city to explore')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(passportControllerProvider).activate(
            cityId: _cityId!,
            durationHours: _durationHours,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passport activated')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _clearPassport() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(passportControllerProvider).clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Returned to your location')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_accessChecked) {
      return const AppSettingsDetailScaffold(
        title: 'Passport',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final passport = ref.watch(passportLocationProvider);
    final countriesAsync = ref.watch(countriesProvider);
    final citiesAsync = _countryId != null
        ? ref.watch(citiesProvider(_countryId!))
        : const AsyncValue<List<ReferenceItem>>.data([]);

    return AppSettingsDetailScaffold(
      title: 'Passport',
      subtitle: 'Temporarily explore matches in another city',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Swipe anywhere',
            subtitle:
                'Change where you discover matches. Your home GPS stays private.',
            children: [
              if (passport.active) ...[
                PremiumInfoRow(
                  label: 'Currently exploring',
                  value: passport.displayLabel,
                  badge: passport.expiresAt != null
                      ? 'Expires ${_formatExpiry(passport.expiresAt!)}'
                      : null,
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _clearPassport,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Return to my location'),
                ),
                const SizedBox(height: AppSpacing.spacingMD),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Choose a destination',
            children: [
              countriesAsync.when(
                data: (countries) => ReferenceBottomSheetField(
                  label: 'Country',
                  hint: 'Select country',
                  selectedId: _countryId,
                  items: countries,
                  groupedStyle: true,
                  searchable: true,
                  showDivider: _countryId != null,
                  onChanged: (value) {
                    setState(() {
                      _countryId = value;
                      _cityId = null;
                    });
                  },
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.spacingMD),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.spacingMD),
                  child: Text('Failed to load countries: $e'),
                ),
              ),
              if (_countryId != null)
                citiesAsync.when(
                  data: (cities) => ReferenceBottomSheetField(
                    label: 'City',
                    hint: 'Select city',
                    selectedId: _cityId,
                    items: cities,
                    groupedStyle: true,
                    searchable: true,
                    enabled: cities.isNotEmpty,
                    showDivider: true,
                    onChanged: (value) => setState(() => _cityId = value),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.spacingMD),
                    child: Text('Failed to load cities: $e'),
                  ),
                ),
              ProfileWizardLayout.pickerTile(
                context: context,
                label: 'Duration',
                value: _durationLabel,
                hint: 'Select duration',
                onTap: _pickDuration,
                showDivider: false,
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
            child: citiesAsync.maybeWhen(
              data: (cities) {
                final cityLabel = _selectedCityLabel(cities) ?? 'this city';
                return GradientButton(
                  text: 'Explore $cityLabel',
                  onPressed:
                      _isSubmitting || _cityId == null ? null : _activatePassport,
                  isLoading: _isSubmitting,
                );
              },
              orElse: () => const GradientButton(
                text: 'Explore',
                onPressed: null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final local = expiresAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} at $hour:$minute';
  }
}
