// Screen: ProfileEditPage
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/metric_slider_tile.dart';
import '../core/theme/spacing_constants.dart';
import '../widgets/profile/edit/profile_image_editor.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/profile/avatar_upload.dart';
import '../widgets/profile/profile_photo_source_sheet.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/profile/data/models/user_image.dart';
import '../features/profile/data/models/update_profile_request.dart';
import '../features/profile/data/models/user_profile.dart';
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
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Profile data
  UserProfile? _profile;
  String _name = '';
  String _bio = '';
  String? _avatarUrl;
  List<UserImage> _images = [];
  List<int> _interestsIds = [];
  int? _height;
  int? _weight;
  bool _smoke = false;
  bool _drink = false;
  bool _gym = false;
  int? _countryId;
  int? _cityId;
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
          _bio = _bioController.text;
          UserImage? primaryImage;
          if (profile.images != null && profile.images!.isNotEmpty) {
            try {
              primaryImage = profile.images!.firstWhere((img) => img.isPrimary);
            } catch (e) {
              primaryImage = profile.images!.first;
            }
          }
          _avatarUrl = primaryImage?.imageUrl;
          _images = List<UserImage>.from(profile.images ?? [])
            ..sort((a, b) => a.order.compareTo(b.order));
          _interestsIds = profile.interests ?? [];
          _height = profile.height;
          _weight = profile.weight;
          _smoke = profile.smoke ?? false;
          _drink = profile.drink ?? false;
          _gym = profile.gym ?? false;
          _countryId = profile.countryId;
          _cityId = profile.cityId;
          _locationUpdatedAt = profile.locationUpdatedAt;
          _locationSource = profile.locationSource;
        });
      }

      try {
        final location = await ref.read(locationApiServiceProvider).getLocation();
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

  int get _primaryImageIndex {
    final idx = _images.indexWhere((img) => img.isPrimary);
    return idx >= 0 ? idx : 0;
  }

  bool get _canPromoteAvatarToPrimary {
    if (_avatarUrl == null || _avatarUrl!.isEmpty || _images.isEmpty) {
      return false;
    }
    final idx = _images.indexWhere((img) => img.imageUrl == _avatarUrl);
    if (idx < 0) return false;
    return !_images[idx].isPrimary;
  }

  Future<void> _pickImage(ImageSource source, {required bool setAsPrimary}) async {
    if (setAsPrimary) {
      final profileCount =
          _images.where((image) => image.type == 'profile').length;
      if (profileCount >= AppConstants.maxPrimaryPhotos) {
        // Primary upload replaces the existing profile photo on the server.
      }
    } else {
      final galleryCount =
          _images.where((image) => image.type == 'gallery').length;
      if (galleryCount >= AppConstants.maxGalleryPhotos ||
          _images.length >= AppConstants.maxTotalProfilePhotos) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${AppConstants.maxGalleryPhotos} gallery photos allowed '
                '(${AppConstants.maxTotalProfilePhotos} total including primary).',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        final file = File(image.path);
        if (setAsPrimary) {
          await _uploadImageAsPrimary(file);
        } else {
          await _uploadImage(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      final uploadedImage =
          await imageService.uploadImage(imageFile, type: 'gallery');
      
      if (mounted) {
        setState(() {
          _images.add(uploadedImage);
          if (_images.length == 1) {
            _avatarUrl = uploadedImage.imageUrl;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery photo added successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageAsPrimary(File imageFile) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      final uploadedImage =
          await imageService.uploadImage(imageFile, type: 'primary');
      await imageService.setPrimaryImage(
        uploadedImage.id,
        isProfilePicture: true,
      );

      if (mounted) {
        setState(() {
          _images = [
            ..._images.map((img) => img.copyWith(isPrimary: false)),
            uploadedImage.copyWith(isPrimary: true),
          ]..sort((a, b) {
              if (a.isPrimary != b.isPrimary) {
                return a.isPrimary ? -1 : 1;
              }
              return a.order.compareTo(b.order);
            });
          _avatarUrl = uploadedImage.imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary photo updated'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload primary photo: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload primary photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteImage(int imageId, int index) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      await imageService.deleteImage(imageId);
      
      if (mounted) {
        setState(() {
          final removed = _images.removeAt(index);
          if (_images.isEmpty) {
            _avatarUrl = null;
          } else if (removed.isPrimary) {
            final nextPrimary = _images.firstWhere(
              (img) => img.isPrimary,
              orElse: () => _images.first,
            );
            _avatarUrl = nextPrimary.imageUrl;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setPrimaryImage(int imageId, int index) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      final image = _images[index];
      await imageService.setPrimaryImage(
        imageId,
        isProfilePicture: image.type == 'profile',
      );
      
      if (mounted) {
        setState(() {
          final image = _images.removeAt(index);
          _images.insert(0, image);
          _images = [
            for (var i = 0; i < _images.length; i++)
              _images[i].copyWith(isPrimary: i == 0, order: i + 1),
          ];
          _avatarUrl = _images.first.imageUrl;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary image updated'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set primary image: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set primary image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reorderImages(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final previous = List<UserImage>.from(_images);
    final updated = List<UserImage>.from(_images);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    setState(() {
      _images = [
        for (var i = 0; i < updated.length; i++)
          updated[i].copyWith(order: i + 1),
      ];
    });

    try {
      final imageService = ref.read(imageServiceProvider);
      await imageService.reorderImages(_images.map((img) => img.id).toList());
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _images = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder photos: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _images = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder photos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setPrimaryFromAvatar() {
    final idx = _images.indexWhere((img) => img.imageUrl == _avatarUrl);
    if (idx >= 0) {
      _setPrimaryImage(_images[idx].id, idx);
    }
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
        height: _height,
        weight: _weight,
        smoke: _smoke,
        drink: _drink,
        gym: _gym,
        interests: _interestsIds.isNotEmpty ? _interestsIds : null,
      );

      await profileService.updateProfile(request);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        final errorMessage = e.errors != null && e.errors!.isNotEmpty
            ? e.getAllErrors()
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $errorMessage'),
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

  void _showImageSourceDialog({required bool setAsPrimary}) {
    ProfilePhotoSourceSheet.show(
      context,
      title: setAsPrimary ? 'Profile photo' : 'Add photo',
      onSourceSelected: (source) =>
          _pickImage(source, setAsPrimary: setAsPrimary),
    );
  }

  void _showAvatarImageSourceDialog() =>
      _showImageSourceDialog(setAsPrimary: true);

  void _showGalleryImageSourceDialog() =>
      _showImageSourceDialog(setAsPrimary: false);

  String _displayLocationUpdated() {
    if (_locationUpdatedAt == null) return 'Never updated';
    final formatted = DateFormat.yMMMd().add_jm().format(_locationUpdatedAt!.toLocal());
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
      final updated = await ref.read(locationApiServiceProvider).updateAdministrativeLocation(
            countryId: _countryId,
            cityId: _cityId,
          );
      ref.invalidate(userLocationProvider);
      if (mounted) {
        setState(() {
          _locationUpdatedAt = updated.locationUpdatedAt;
          _locationSource = updated.locationSource ?? 'city';
          _isUpdatingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated')),
        );
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
            final location = await ref.read(locationApiServiceProvider).getLocation();
            setState(() {
              _locationUpdatedAt = location.locationUpdatedAt;
              _locationSource = location.locationSource ?? 'gps';
            });
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS location updated')),
          );
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
            PremiumSettingsGroup(
              title: 'Profile photo',
              children: [
                Center(
                    child: AvatarUpload(
                      imageUrl: _avatarUrl,
                      name: _name,
                      size: 120.0,
                      showPrimaryBadge: _avatarUrl != null && _avatarUrl!.isNotEmpty,
                      onUpload: _showAvatarImageSourceDialog,
                      onEdit: _showAvatarImageSourceDialog,
                      onSetPrimary:
                          _canPromoteAvatarToPrimary ? _setPrimaryFromAvatar : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Photos',
              children: [
                ProfileImageEditor(
                  imageUrls: _images.map((img) => img.imageUrl).toList(),
                  primaryIndex: _primaryImageIndex,
                  maxImages: AppConstants.maxTotalProfilePhotos,
                  onImageAdd: (_) => _showGalleryImageSourceDialog(),
                  onImageDelete: (index) {
                    if (index < _images.length) {
                      _deleteImage(_images[index].id, index);
                    }
                  },
                  onImageReorder: _reorderImages,
                  onImageSetPrimary: (index) {
                    if (index < _images.length) {
                      _setPrimaryImage(_images[index].id, index);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'About me',
              children: [
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell others about yourself',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (value) => _bio = value,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Personal details',
              children: [
                HeightSliderTile(
                  value: _height ?? 170,
                  onChanged: (value) => setState(() => _height = value),
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                WeightSliderTile(
                  value: _weight ?? 70,
                  onChanged: (value) => setState(() => _weight = value),
                ),
                PremiumToggleRow(
                  title: 'Smoking',
                  subtitle: 'Do you smoke?',
                  value: _smoke,
                  onChanged: (value) => setState(() => _smoke = value),
                ),
                PremiumToggleRow(
                  title: 'Drinking',
                  subtitle: 'Do you drink alcohol?',
                  value: _drink,
                  onChanged: (value) => setState(() => _drink = value),
                ),
                PremiumToggleRow(
                  title: 'Gym',
                  subtitle: 'Do you work out regularly?',
                  value: _gym,
                  onChanged: (value) => setState(() => _gym = value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Location',
              children: [
                countriesAsync.when(
                  data: (countries) => ReferenceBottomSheetField(
                    label: 'Country',
                    hint: 'Select your country',
                    selectedId: _countryId,
                    items: countries,
                    groupedStyle: true,
                    onChanged: (value) {
                      setState(() {
                        _countryId = value;
                        _cityId = null;
                      });
                    },
                    searchable: true,
                  ),
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
                    data: (cities) => ReferenceBottomSheetField(
                      label: 'City',
                      hint: 'Select your city',
                      selectedId: _cityId,
                      items: cities,
                      groupedStyle: true,
                      onChanged: (value) => setState(() => _cityId = value),
                      enabled: cities.isNotEmpty,
                      searchable: true,
                    ),
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
                  onPressed: _isUpdatingLocation ? null : _saveAdministrativeLocation,
                  child: const Text('Save country & city'),
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
                      : const Text('Update my GPS location'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Profile info',
              children: [
                PremiumInfoRow(
                  label: 'Name',
                  value: _displayName(),
                ),
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
                PremiumInfoRow(
                  label: 'Age',
                  value: _displayAge(),
                ),
              ],
            ),
            const AppSettingsSectionFootnote(
              text: 'Name, email, gender, and age are managed in account settings.',
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
                  value: _displayList(
                    _profile?.interestTitles,
                    _interestsIds,
                  ),
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
              padding: const EdgeInsets.fromLTRB(
                AppSettingsLayout.horizontalPadding,
                AppSpacing.spacingXL,
                AppSettingsLayout.horizontalPadding,
                0,
              ),
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
