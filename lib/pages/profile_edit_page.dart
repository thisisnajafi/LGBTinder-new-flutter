// Screen: ProfileEditPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/theme/spacing_constants.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/profile/edit/profile_edit_about_me_section.dart';
import '../widgets/profile/edit/profile_edit_bio_field.dart';
import '../widgets/profile/edit/profile_edit_photos_section.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/profile/providers/profile_page_cache_provider.dart';
import '../features/profile/data/models/update_profile_request.dart';
import '../features/profile/data/models/user_profile.dart';
import '../features/profile/data/models/user_image.dart';
import '../shared/models/api_error.dart';
import '../features/reference_data/providers/reference_data_providers.dart';
import '../features/reference_data/data/models/reference_item.dart';
import '../widgets/common/reference_bottom_sheet_field.dart';
import '../core/location/location_providers.dart';
import '../core/location/location_sync_service.dart';
import '../core/location/widgets/location_permission_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

/// Profile edit page - Edit user's own profile
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bioController = TextEditingController();
  final ProfileEditAboutMeValues _aboutMe = ProfileEditAboutMeValues();

  bool _isLoading = false;
  bool _isSaving = false;

  UserProfile? _profile;
  String _name = '';
  List<UserImage> _initialImages = const [];
  List<int> _interestsIds = [];
  int? _countryId;
  int? _cityId;
  String? _locationMarketNotice;
  DateTime? _locationUpdatedAt;
  String? _locationSource;
  bool _isUpdatingLocation = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getMyProfile();

      if (mounted) {
        setState(() {
          _profile = profile;
          _name = '${profile.firstName} ${profile.lastName}'.trim();
          _bioController.text = profile.profileBio ?? '';
          _initialImages = List<UserImage>.from(profile.images ?? []);
          _interestsIds = profile.interests ?? [];
          _aboutMe.height = profile.height;
          _aboutMe.weight = profile.weight;
          _aboutMe.smoke = profile.smoke ?? false;
          _aboutMe.drink = profile.drink ?? false;
          _aboutMe.gym = profile.gym ?? false;
          _countryId = profile.countryId;
          _cityId = profile.cityId;
          _locationUpdatedAt = profile.locationUpdatedAt;
          _locationSource = profile.locationSource;
        });
      }

      try {
        final location = await ref
            .read(locationApiServiceProvider)
            .getLocation();
        if (mounted) {
          setState(() {
            _countryId ??= location.countryId;
            _cityId ??= location.cityId;
            _locationUpdatedAt ??= location.locationUpdatedAt;
            _locationSource ??= location.locationSource;
          });
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncProfileCache() async {
    await ref.read(profilePageCacheProvider.notifier).refresh();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profileService = ref.read(profileServiceProvider);

      final bio = _bioController.text.trim();
      final request = UpdateProfileRequest(
        profileBio: bio.isNotEmpty ? bio : null,
        height: _aboutMe.height,
        weight: _aboutMe.weight,
        smoke: _aboutMe.smoke,
        drink: _aboutMe.drink,
        gym: _aboutMe.gym,
        interests: _interestsIds.isNotEmpty ? _interestsIds : null,
      );

      await profileService.updateProfile(request);
      await _syncProfileCache();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _displayLocationUpdated() {
    if (_locationUpdatedAt == null) return 'Never updated';
    final formatted = DateFormat.yMMMd().add_jm().format(
      _locationUpdatedAt!.toLocal(),
    );
    final source = _locationSource == 'gps' ? 'GPS' : 'City';
    return '$formatted ($source)';
  }

  Future<void> _saveAdministrativeLocation() async {
    if (_countryId == null || _cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both country and city')),
      );
      return;
    }

    setState(() => _isUpdatingLocation = true);
    try {
      final updated = await ref
          .read(locationApiServiceProvider)
          .updateAdministrativeLocation(countryId: _countryId, cityId: _cityId);
      ref.invalidate(userLocationProvider);
      if (mounted) {
        setState(() {
          _locationUpdatedAt = updated.locationUpdatedAt;
          _locationSource = updated.locationSource ?? 'city';
          _isUpdatingLocation = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location updated')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update location: $e')),
        );
      }
    }
  }

  Future<void> _updateGpsLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final permission = await locationService.checkPermission();
    final permanentlyDenied = permission == LocationPermission.deniedForever;

    if (!mounted) return;
    await LocationPermissionSheet.show(
      context,
      permanentlyDenied: permanentlyDenied,
      onEnable: () async {
        setState(() => _isUpdatingLocation = true);
        final result = await ref
            .read(locationSyncServiceProvider)
            .syncIfNeeded(discoverOpen: true, force: true);
        ref.invalidate(userLocationProvider);
        if (!mounted) return;
        if (result == LocationSyncResult.success) {
          try {
            final location = await ref
                .read(locationApiServiceProvider)
                .getLocation();
            if (!mounted) return;
            setState(() {
              _locationUpdatedAt = location.locationUpdatedAt;
              _locationSource = location.locationSource ?? 'gps';
            });
          } catch (_) {}
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('GPS location updated')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get GPS location')),
          );
        }
        setState(() => _isUpdatingLocation = false);
      },
      onUseCity: _saveAdministrativeLocation,
    );
  }

  String _displayName() {
    final name = _name.trim();
    return name.isEmpty ? 'Not set' : name;
  }

  String _displayAge() {
    final birthDate = _profile?.birthDate;
    if (birthDate == null || birthDate.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(birthDate);
      final now = DateTime.now();
      var age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return '$age years old';
    } catch (_) {
      return birthDate;
    }
  }

  String _displayList(List<String>? titles, List<int>? ids) {
    if (titles != null && titles.isNotEmpty) return titles.join(', ');
    if (ids != null && ids.isNotEmpty) return '${ids.length} selected';
    return 'Not set';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppSettingsDetailScaffold(
        title: 'Edit profile',
        subtitle: 'Photos, bio, and details',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final countriesAsync = ref.watch(countriesProvider);
    final citiesAsync = _countryId != null
        ? ref.watch(citiesProvider(_countryId!))
        : const AsyncValue<List<ReferenceItem>>.data([]);

    return AppSettingsDetailScaffold(
      title: 'Edit profile',
      subtitle: 'Photos, bio, and details',
      body: Form(
        key: _formKey,
        child: AppSettingsDetailList(
          children: [
            ProfileEditPhotosSection(
              key: ValueKey(_profile?.id ?? 'photos'),
              initialImages: _initialImages,
              name: _name,
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Personality',
              subtitle: 'Let your authentic self shine',
              children: [ProfileEditBioField(controller: _bioController)],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            ProfileEditAboutMeSection(values: _aboutMe),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Location',
              children: [
                countriesAsync.when(
                  data: (countries) {
                    if (_countryId != null &&
                        !countries.any((c) => c.id == _countryId)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          _countryId = null;
                          _cityId = null;
                          _locationMarketNotice =
                              'Your previous location is no longer available. Please choose a supported country and city.';
                        });
                      });
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_locationMarketNotice != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _locationMarketNotice!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ReferenceBottomSheetField(
                          label: 'Country',
                          hint: countries.isEmpty
                              ? 'No supported countries available'
                              : 'Select your country',
                          selectedId: _countryId,
                          items: countries,
                          groupedStyle: true,
                          onChanged: (value) {
                            setState(() {
                              _countryId = value;
                              _cityId = null;
                              _locationMarketNotice = null;
                            });
                          },
                          searchable: true,
                          enabled: countries.isNotEmpty,
                        ),
                      ],
                    );
                  },
                  loading: () => const PremiumInfoRow(
                    label: 'Country',
                    value: 'Loading...',
                  ),
                  error: (e, _) => const PremiumInfoRow(
                    label: 'Country',
                    value: 'Failed to load',
                  ),
                ),
                if (_countryId != null)
                  citiesAsync.when(
                    data: (cities) {
                      if (_cityId != null &&
                          !cities.any((c) => c.id == _cityId)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _cityId = null;
                            _locationMarketNotice =
                                'Your previous city is no longer available. Please choose a supported city.';
                          });
                        });
                      }
                      return ReferenceBottomSheetField(
                        label: 'City',
                        hint: cities.isEmpty
                            ? 'No supported cities for this country'
                            : 'Select your city',
                        selectedId: _cityId,
                        items: cities,
                        groupedStyle: true,
                        onChanged: (value) => setState(() {
                          _cityId = value;
                          _locationMarketNotice = null;
                        }),
                        enabled: cities.isNotEmpty,
                        searchable: true,
                      );
                    },
                    loading: () => const PremiumInfoRow(
                      label: 'City',
                      value: 'Loading...',
                    ),
                    error: (e, _) => const PremiumInfoRow(
                      label: 'City',
                      value: 'Failed to load',
                    ),
                  ),
                PremiumInfoRow(
                  label: 'Last updated',
                  value: _displayLocationUpdated(),
                ),
                OutlinedButton(
                  onPressed: _isUpdatingLocation
                      ? null
                      : _saveAdministrativeLocation,
                  child: const AppText('Save country & city', maxLines: 1),
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                FilledButton(
                  onPressed: _isUpdatingLocation ? null : _updateGpsLocation,
                  child: _isUpdatingLocation
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const AppText('Update my GPS location', maxLines: 1),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Profile info',
              children: [
                PremiumInfoRow(label: 'Name', value: _displayName()),
                PremiumInfoRow(
                  label: 'Email',
                  value: _profile?.email.isNotEmpty == true
                      ? _profile!.email
                      : 'Not set',
                  badge: _profile?.isEmailVerified == true ? 'Verified' : null,
                ),
                PremiumInfoRow(
                  label: 'Gender',
                  value: (_profile?.gender?.isNotEmpty == true)
                      ? _profile!.gender!
                      : 'Not set',
                ),
                PremiumInfoRow(label: 'Age', value: _displayAge()),
              ],
            ),
            const AppSettingsSectionFootnote(
              text:
                  'Name, email, gender, and age are managed in account settings.',
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Work & education',
              children: [
                PremiumInfoRow(
                  label: 'Occupation',
                  value: _displayList(_profile?.jobTitles, _profile?.jobs),
                ),
                PremiumInfoRow(
                  label: 'Education',
                  value: _displayList(
                    _profile?.educationTitles,
                    _profile?.educations,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Interests & languages',
              children: [
                PremiumInfoRow(
                  label: 'Interests',
                  value: _displayList(_profile?.interestTitles, _interestsIds),
                ),
                PremiumInfoRow(
                  label: 'Languages',
                  value: _displayList(null, _profile?.languages),
                ),
              ],
            ),
            const AppSettingsSectionFootnote(
              text:
                  'Update interests and matching preferences from discovery settings.',
            ),
            Padding(
              padding: ResponsivePadding.horizontal(
                context,
              ).copyWith(top: AppSpacing.spacingXL),
              child: GradientButton(
                text: 'Save changes',
                onPressed: _isSaving ? null : _saveProfile,
                isLoading: _isSaving,
                isFullWidth: true,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingXXL),
          ],
        ),
      ),
    );
  }
}
