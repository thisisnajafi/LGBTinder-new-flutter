// Screen: ProfileEditPage
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/profile/avatar_upload.dart';
import '../widgets/profile/edit/profile_image_editor.dart';
import '../widgets/profile/edit/profile_field_editor.dart';
import '../widgets/profile/edit/profile_section_editor.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../features/profile/providers/profile_providers.dart';
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
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Profile data
  String _name = '';
  String _bio = '';
  String? _avatarUrl;
  List<UserImage> _images = [];
  List<int> _interestsIds = [];
  
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
          _name = '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
          _bio = profile.profileBio ?? '';
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
              imageUrl: _images[i].imageUrl,
              isPrimary: i == index,
              order: _images[i].order,
            );
          }
          // Move to first position
          final image = _images.removeAt(index);
          _images.insert(0, UserImage(
            id: image.id,
            imageUrl: image.imageUrl,
            isPrimary: true,
            order: 0,
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
      
      final request = UpdateProfileRequest(
        profileBio: _bio.isNotEmpty ? _bio : null,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBarCustom(
          title: 'Edit Profile',
          showBackButton: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Edit Profile',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar section
              SectionHeader(
                title: 'Profile Photo',
                icon: Icons.person,
              ),
              Center(
                child: AvatarUpload(
                  imageUrl: _avatarUrl,
                  name: _name,
                  size: 120.0,
                  onUpload: () => _showImageSourceDialog(),
                  onEdit: () => _showImageSourceDialog(),
                ),
              ),
              const SizedBox(height: 20),
              DividerCustom(),
              
              // Images section
              SectionHeader(
                title: 'Photos',
                icon: Icons.photo_library,
              ),
              ProfileImageEditor(
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
              DividerCustom(),

              // Basic info section
              SectionHeader(
                title: 'Basic Information',
                icon: Icons.info,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Note: Name, Age, Location are typically not editable via Update Profile API
                    // They are set during registration and may require separate endpoints
                    const SizedBox(height: 16),
                    ProfileFieldEditor(
                      label: 'Bio',
                      initialValue: _bio,
                      maxLines: 5,
                      maxLength: 500,
                      onSave: (value) {
                        setState(() {
                          _bio = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              DividerCustom(),

              // Interests section
              SectionHeader(
                title: 'Interests',
                icon: Icons.favorite,
                actionLabel: 'Edit',
                onAction: () {
                  // TODO: Open interests editor with reference data
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _interestsIds.isEmpty
                    ? Text(
                        'No interests selected',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Text(
                        '${_interestsIds.length} interests selected',
                        style: TextStyle(color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 20),
              DividerCustom(),

              // Save button
              Padding(
                padding: const EdgeInsets.all(16),
                child: GradientButton(
                  text: 'Save Changes',
                  onPressed: _isSaving ? null : _saveProfile,
                  isLoading: _isSaving,
                  isFullWidth: true,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
