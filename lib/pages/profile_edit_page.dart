// Screen: ProfileEditPage
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/theme/spacing_constants.dart';
import '../widgets/profile/edit/profile_image_editor.dart';
import '../core/widgets/app_grouped_list_card.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/profile/avatar_upload.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/profile/data/models/user_image.dart';
import '../features/profile/data/models/update_profile_request.dart';
import '../features/profile/data/models/user_profile.dart';
import '../shared/models/api_error.dart';

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
          _images = profile.images ?? [];
          _interestsIds = profile.interests ?? [];
          _height = profile.height;
          _weight = profile.weight;
          _smoke = profile.smoke ?? false;
          _drink = profile.drink ?? false;
          _gym = profile.gym ?? false;
        });
      }
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        final file = File(image.path);
        await _uploadImage(file);
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
      final uploadedImage = await imageService.uploadImage(imageFile);
      
      if (mounted) {
        setState(() {
          _images.add(uploadedImage);
          if (_images.length == 1) {
            _avatarUrl = uploadedImage.imageUrl;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
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

  Future<void> _deleteImage(int imageId, int index) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      await imageService.deleteImage(imageId);
      
      if (mounted) {
        setState(() {
          _images.removeAt(index);
          if (_images.isNotEmpty) {
            _avatarUrl = _images.first.imageUrl;
          } else {
            _avatarUrl = null;
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
      await imageService.setPrimaryImage(imageId);
      
      if (mounted) {
        setState(() {
          // Update primary flags
          for (var i = 0; i < _images.length; i++) {
            _images[i] = UserImage(
              id: _images[i].id,
              userId: _images[i].userId,
              path: _images[i].path,
              type: _images[i].type,
              isPrimary: i == index,
              order: _images[i].order,
              sizes: _images[i].sizes,
            );
          }
          // Move to first position
          final image = _images.removeAt(index);
          _images.insert(0, UserImage(
            id: image.id,
            userId: image.userId,
            path: image.path,
            type: image.type,
            isPrimary: true,
            order: 0,
            sizes: image.sizes,
          ));
          _avatarUrl = image.imageUrl;
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _displayName() {
    final name = _name.trim();
    return name.isEmpty ? 'Not set' : name;
  }

  String _displayLocation() {
    final parts = [_profile?.city, _profile?.country]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Not set' : parts.join(', ');
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
        title: 'Edit Profile',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppSettingsDetailScaffold(
      title: 'Edit Profile',
      body: Form(
        key: _formKey,
        child: AppSettingsDetailList(
          children: [
            AppGroupedListSection(
              title: 'Profile Photo',
              padding: AppSettingsLayout.firstSectionPadding,
              children: [
                AppSettingsInset(
                  child: Center(
                    child: AvatarUpload(
                      imageUrl: _avatarUrl,
                      name: _name,
                      size: 120.0,
                      onUpload: _showImageSourceDialog,
                      onEdit: _showImageSourceDialog,
                    ),
                  ),
                ),
              ],
            ),
            AppGroupedListSection(
              title: 'Photos',
              padding: AppSettingsLayout.sectionPadding,
              children: [
                AppSettingsInset(
                  child: ProfileImageEditor(
                    imageUrls: _images.map((img) => img.imageUrl).toList(),
                    onImageAdd: (_) => _showImageSourceDialog(),
                    onImageDelete: (index) {
                      if (index < _images.length) {
                        _deleteImage(_images[index].id, index);
                      }
                    },
                    onImageSetPrimary: (index) {
                      if (index < _images.length) {
                        _setPrimaryImage(_images[index].id, index);
                      }
                    },
                  ),
                ),
              ],
            ),
            AppGroupedListSection(
              title: 'About Me',
              padding: AppSettingsLayout.sectionPadding,
              children: [
                AppSettingsInset(
                  child: TextFormField(
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
                ),
              ],
            ),
            AppGroupedListSection(
              title: 'Personal Details',
              padding: AppSettingsLayout.sectionPadding,
              children: [
                AppSettingsInset(
                  child: TextFormField(
                    initialValue: _height?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      hintText: 'Enter your height',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _height = int.tryParse(value.trim());
                    },
                  ),
                ),
                const AppGroupedRowSeparator(),
                AppSettingsInset(
                  child: TextFormField(
                    initialValue: _weight?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'Enter your weight',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _weight = int.tryParse(value.trim());
                    },
                  ),
                ),
                AppGroupedSwitchTile(
                  label: 'Smoking',
                  subtitle: 'Do you smoke?',
                  value: _smoke,
                  onChanged: (value) => setState(() => _smoke = value),
                ),
                AppGroupedSwitchTile(
                  label: 'Drinking',
                  subtitle: 'Do you drink alcohol?',
                  value: _drink,
                  onChanged: (value) => setState(() => _drink = value),
                ),
                AppGroupedSwitchTile(
                  label: 'Gym',
                  subtitle: 'Do you work out regularly?',
                  value: _gym,
                  onChanged: (value) => setState(() => _gym = value),
                  showDivider: false,
                ),
              ],
            ),
            AppGroupedListSection(
              title: 'Profile Info',
              padding: AppSettingsLayout.sectionPadding,
              children: [
                AppGroupedInfoTile(
                  label: 'Name',
                  value: _displayName(),
                ),
                AppGroupedInfoTile(
                  label: 'Email',
                  value: _profile?.email.isNotEmpty == true
                      ? _profile!.email
                      : 'Not set',
                  badge: _profile?.isEmailVerified == true ? 'Verified' : null,
                ),
                AppGroupedInfoTile(
                  label: 'Gender',
                  value: (_profile?.gender?.isNotEmpty == true)
                      ? _profile!.gender!
                      : 'Not set',
                ),
                AppGroupedInfoTile(
                  label: 'Age',
                  value: _displayAge(),
                ),
                AppGroupedInfoTile(
                  label: 'Location',
                  value: _displayLocation(),
                  showDivider: false,
                ),
              ],
            ),
            const AppSettingsSectionFootnote(
              text:
                  'Name, email, gender, and location are managed in account settings.',
            ),
            AppGroupedListSection(
              title: 'Work & Education',
              padding: AppSettingsLayout.sectionPadding,
              children: [
                AppGroupedInfoTile(
                  label: 'Occupation',
                  value: _displayList(_profile?.jobTitles, _profile?.jobs),
                ),
                AppGroupedInfoTile(
                  label: 'Education',
                  value: _displayList(
                    _profile?.educationTitles,
                    _profile?.educations,
                  ),
                  showDivider: false,
                ),
              ],
            ),
            AppGroupedListSection(
              title: 'Interests & Languages',
              padding: AppSettingsLayout.sectionPadding,
              children: [
                AppGroupedInfoTile(
                  label: 'Interests',
                  value: _displayList(
                    _profile?.interestTitles,
                    _interestsIds,
                  ),
                ),
                AppGroupedInfoTile(
                  label: 'Languages',
                  value: _displayList(null, _profile?.languages),
                  showDivider: false,
                ),
              ],
            ),
            const AppSettingsSectionFootnote(
              text:
                  'Update interests and matching preferences from discovery settings.',
            ),
            Padding(
              padding: AppSettingsLayout.sectionPadding,
              child: GradientButton(
                text: 'Save Changes',
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
