import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/location/passport_provider.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../features/payments/data/services/plan_limits_service.dart';
import '../../../../features/reference_data/data/models/reference_item.dart';
import '../../../../features/reference_data/providers/reference_data_providers.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/utils/plan_guard.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/common/reference_bottom_sheet_field.dart';

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
        SnackBar(content: Text(e.toString())),
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
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_accessChecked) {
      return const AppPageScaffold(
        title: 'Passport',
        showBackButton: true,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final passport = ref.watch(passportLocationProvider);
    final countriesAsync = ref.watch(countriesProvider);
    final citiesAsync = _countryId != null
        ? ref.watch(citiesProvider(_countryId!))
        : const AsyncValue<List<ReferenceItem>>.data([]);

    return AppPageScaffold(
      title: 'Passport',
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.contentPadding),
        children: [
          Row(
            children: [
              AppSvgIcon(
                assetPath: AppIcons.map,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Text(
                  'Swipe anywhere',
                  style: AppTypography.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          Text(
            'Temporarily change where you discover matches. Your home GPS stays private.',
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (passport.active) ...[
            const SizedBox(height: AppSpacing.spacingLG),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Currently exploring',
                      style: AppTypography.labelMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      passport.displayLabel,
                      style: AppTypography.titleMedium,
                    ),
                    if (passport.expiresAt != null) ...[
                      const SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        'Expires ${_formatExpiry(passport.expiresAt!)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.spacingMD),
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
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.spacingLG),
          Text(
            'Choose a destination',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          countriesAsync.when(
            data: (countries) => ReferenceBottomSheetField(
              label: 'Country',
              hint: 'Select country',
              selectedId: _countryId,
              items: countries,
              groupedStyle: true,
              searchable: true,
              onChanged: (value) {
                setState(() {
                  _countryId = value;
                  _cityId = null;
                });
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load countries: $e'),
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
                onChanged: (value) => setState(() => _cityId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load cities: $e'),
            ),
          const SizedBox(height: AppSpacing.spacingMD),
          DropdownButtonFormField<int>(
            value: _durationHours,
            decoration: const InputDecoration(
              labelText: 'Duration',
            ),
            items: const [
              DropdownMenuItem(value: 24, child: Text('24 hours')),
              DropdownMenuItem(value: 48, child: Text('48 hours')),
              DropdownMenuItem(value: 72, child: Text('72 hours')),
              DropdownMenuItem(value: 168, child: Text('1 week')),
            ],
            onChanged: _isSubmitting
                ? null
                : (value) {
                    if (value != null) setState(() => _durationHours = value);
                  },
          ),
          const SizedBox(height: AppSpacing.spacingLG),
          citiesAsync.maybeWhen(
            data: (cities) {
              final cityLabel = _selectedCityLabel(cities) ?? 'this city';
              return GradientButton(
                text: 'Explore $cityLabel',
                onPressed: _isSubmitting || _cityId == null ? null : _activatePassport,
                isLoading: _isSubmitting,
              );
            },
            orElse: () => const GradientButton(
              text: 'Explore',
              onPressed: null,
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
