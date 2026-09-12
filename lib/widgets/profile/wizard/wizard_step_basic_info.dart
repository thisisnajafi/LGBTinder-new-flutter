import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/country_phone_utils.dart';
import '../../../core/widgets/inputs/country_phone_input.dart';
import '../../../features/profile/providers/profile_wizard_provider.dart';
import '../../../features/profile/providers/wizard_reference_cache_provider.dart';
import '../../../features/reference_data/data/models/reference_item.dart';
import '../../../widgets/common/reference_bottom_sheet_field.dart';
import '../profile_wizard_layout.dart';
import 'wizard_step_support.dart';

/// Step 2 — name, location, phone, gender, birth date.
class WizardStepBasicInfo extends ConsumerWidget {
  const WizardStepBasicInfo({
    super.key,
    required this.nameController,
    required this.phoneNumberController,
    required this.countryCodeController,
    required this.phoneFormKey,
  });

  static const pageKey = ValueKey<String>('wizard-step-basic-info');

  final TextEditingController nameController;
  final TextEditingController phoneNumberController;
  final TextEditingController countryCodeController;
  final GlobalKey<FormState> phoneFormKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final refs = ref.watch(wizardReferenceCacheProvider);
    final citiesAsync = ref.watch(wizardCitiesProvider);
    final countryId = ref.watch(
      profileWizardProvider.select((s) => s.countryId),
    );
    final cityId = ref.watch(profileWizardProvider.select((s) => s.cityId));
    final genderId = ref.watch(profileWizardProvider.select((s) => s.genderId));
    final birthDate = ref.watch(
      profileWizardProvider.select((s) => s.birthDate),
    );
    final notice = ref.watch(
      profileWizardProvider.select((s) => s.locationMarketNotice),
    );
    final selectedCountry = ref.watch(
      profileWizardProvider.select((s) => s.selectedCountry),
    );
    final countryCode = ref.watch(
      profileWizardProvider.select((s) => s.countryCode),
    );

    return ProfileWizardLayout.stepList(
      children: [
        ProfileWizardLayout.section('Basic Information & Contact', [
          ProfileWizardLayout.inset(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                  ),
                  onChanged: (value) =>
                      ref.read(profileWizardProvider.notifier).setName(value),
                ),
              ],
            ),
          ),
          refs.countries.when(
            data: (countries) {
              _syncCountry(ref, countries, countryId);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notice != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        notice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  ReferenceBottomSheetField(
                    label: 'Country',
                    hint: countries.isEmpty
                        ? 'No supported countries available'
                        : 'Select your country',
                    selectedId: countryId,
                    items: countries,
                    groupedStyle: true,
                    onChanged: (value) {
                      final selected = countries.firstWhere(
                        (c) => c.id == value,
                        orElse: () => ReferenceItem(
                          id: -1,
                          title: '',
                          phoneCode: countryCode,
                        ),
                      );
                      final item = selected.id != -1 ? selected : null;
                      final newCode = CountryPhoneUtils.dialCodeForCountry(
                        item,
                      );
                      countryCodeController.text = newCode;
                      ref
                          .read(profileWizardProvider.notifier)
                          .setCountry(
                            countryId: value,
                            selectedCountry: item,
                            countryCode: newCode,
                          );
                    },
                    required: true,
                    searchable: true,
                    enabled: countries.isNotEmpty,
                  ),
                ],
              );
            },
            loading: () => WizardStepSupport.loadingField(
              label: 'Country',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Country',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
          if (countryId != null)
            citiesAsync.when(
              data: (cities) {
                _syncCity(ref, cities, cityId);
                return ReferenceBottomSheetField(
                  label: 'City',
                  hint: cities.isEmpty
                      ? 'No supported cities for this country'
                      : 'Select your city',
                  selectedId: cityId,
                  items: cities,
                  groupedStyle: true,
                  onChanged: (value) {
                    ref.read(profileWizardProvider.notifier).setCity(value);
                  },
                  required: true,
                  enabled: cities.isNotEmpty,
                  searchable: true,
                );
              },
              loading: () => WizardStepSupport.loadingField(
                label: 'City',
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                isDark: isDark,
              ),
              error: (error, _) => WizardStepSupport.errorField(
                label: 'City',
                error: error,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                isDark: isDark,
              ),
            ),
          refs.countries.when(
            data: (countries) {
              final matched = countries.firstWhere(
                (c) => c.id == countryId,
                orElse: () => ReferenceItem(id: -1, title: ''),
              );
              final effectiveCountry = matched.id != -1
                  ? matched
                  : selectedCountry;
              final effectiveCountryCode = CountryPhoneUtils.dialCodeForCountry(
                effectiveCountry,
              );

              if (countryCodeController.text != effectiveCountryCode) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  countryCodeController.text = effectiveCountryCode;
                });
              }

              return ProfileWizardLayout.inset(
                child: Form(
                  key: phoneFormKey,
                  child: CountryPhoneInput(
                    country: effectiveCountry,
                    nationalController: phoneNumberController,
                    dialCodeController: countryCodeController,
                    onPhoneChanged: (parsed) {
                      final notifier = ref.read(profileWizardProvider.notifier);
                      if (parsed != null) {
                        notifier.setPhone(
                          phoneNumber: parsed.e164,
                          countryCode: parsed.dialCode,
                        );
                      } else {
                        notifier.setPhone(
                          phoneNumber: CountryPhoneUtils.digitsOnly(
                            phoneNumberController.text,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
            loading: () => WizardStepSupport.loadingField(
              label: 'Phone Number',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Phone Number',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
          refs.genders.when(
            data: (genders) => ReferenceBottomSheetField(
              label: 'Gender',
              hint: 'Select your gender',
              selectedId: genderId,
              items: genders,
              groupedStyle: true,
              onChanged: (value) {
                ref.read(profileWizardProvider.notifier).setGender(value);
              },
              required: true,
              searchable: true,
            ),
            loading: () => WizardStepSupport.loadingField(
              label: 'Gender',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Gender',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
          ProfileWizardLayout.pickerTile(
            context: context,
            label: 'Birth Date',
            value: birthDate != null
                ? '${birthDate.day}/${birthDate.month}/${birthDate.year}'
                : null,
            hint: 'Select your birth date',
            required: true,
            showDivider: false,
            onTap: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate:
                    birthDate ??
                    DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime(1950),
                lastDate: DateTime.now().subtract(
                  const Duration(days: 365 * 18),
                ),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.accentPurple,
                        onPrimary: Colors.white,
                        surface: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        onSurface: textColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              FocusManager.instance.primaryFocus?.unfocus();
              if (picked != null) {
                ref.read(profileWizardProvider.notifier).setBirthDate(picked);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                });
              }
            },
          ),
        ], first: true),
      ],
    );
  }

  static void _syncCountry(
    WidgetRef ref,
    List<ReferenceItem> countries,
    int? countryId,
  ) {
    if (countryId == null) return;
    if (countries.any((c) => c.id == countryId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileWizardProvider.notifier).clearUnsupportedCountry();
    });
  }

  static void _syncCity(
    WidgetRef ref,
    List<ReferenceItem> cities,
    int? cityId,
  ) {
    if (cityId == null) return;
    if (cities.any((c) => c.id == cityId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileWizardProvider.notifier).clearUnsupportedCity();
    });
  }
}
