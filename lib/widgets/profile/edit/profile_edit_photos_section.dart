import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_media_picker.dart';
import '../../../core/utils/image_upload_compressor.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../features/profile/data/models/user_image.dart';
import '../../../features/profile/presentation/widgets/own_profile/profile_photo_utils.dart';
import '../../../features/profile/providers/profile_page_cache_provider.dart';
import '../../../features/profile/providers/profile_providers.dart';
import '../../../shared/models/api_error.dart';
import '../../profile/avatar_upload.dart';
import '../../profile/profile_photo_source_sheet.dart';
import 'profile_image_editor.dart';

/// Isolated photo editor: picker, compress-before-preview, upload, gallery.
///
/// PERF-PAGE-PROFILEEDIT-001 / 003.
class ProfileEditPhotosSection extends ConsumerStatefulWidget {
  const ProfileEditPhotosSection({
    super.key,
    required this.initialImages,
    required this.name,
  });

  static const sectionKey = ValueKey<String>('profile-edit-photos');
  static const galleryKey = ValueKey<String>('profile-edit-gallery');

  final List<UserImage> initialImages;
  final String name;

  @override
  ConsumerState<ProfileEditPhotosSection> createState() =>
      _ProfileEditPhotosSectionState();
}

class _ProfileEditPhotosSectionState
    extends ConsumerState<ProfileEditPhotosSection> {
  late List<UserImage> _images;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _applyImages(widget.initialImages);
  }

  @override
  void didUpdateWidget(covariant ProfileEditPhotosSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameImageIds(oldWidget.initialImages, widget.initialImages)) {
      setState(() => _applyImages(widget.initialImages));
    }
  }

  void _applyImages(List<UserImage> images) {
    _images = List<UserImage>.from(images)
      ..sort((a, b) => a.order.compareTo(b.order));
    final primary = primaryProfileImage(_images);
    _avatarUrl = primary?.avatarDisplayUrl;
  }

  bool _sameImageIds(List<UserImage> a, List<UserImage> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].isPrimary != b[i].isPrimary) {
        return false;
      }
    }
    return true;
  }

  bool get _canPromoteAvatarToPrimary {
    if (_avatarUrl == null || _avatarUrl!.isEmpty || _images.isEmpty) {
      return false;
    }
    final idx = _images.indexWhere((img) => img.imageUrl == _avatarUrl);
    if (idx < 0) return false;
    return !_images[idx].isPrimary;
  }

  List<UserImage> get _galleryImages => galleryProfileImages(_images);

  int? _imageIndexForGalleryIndex(int galleryIndex) {
    if (galleryIndex < 0 || galleryIndex >= _galleryImages.length) {
      return null;
    }
    final targetId = _galleryImages[galleryIndex].id;
    return _images.indexWhere((img) => img.id == targetId);
  }

  Future<void> _syncProfileCache() async {
    await ref.read(profilePageCacheProvider.notifier).refresh();
  }

  Future<void> _pickImage(
    ImageSource source, {
    required bool setAsPrimary,
  }) async {
    if (setAsPrimary) {
      final profileCount = _images
          .where((image) => image.type == 'profile')
          .length;
      if (profileCount >= AppConstants.maxPrimaryPhotos) {
        // Primary upload replaces the existing profile photo on the server.
      }
    } else {
      final galleryCount = _images
          .where((image) => image.type == 'gallery')
          .length;
      if (galleryCount >= AppConstants.maxGalleryPhotos) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${AppConstants.maxGalleryPhotos} images allowed.',
              ),
              backgroundColor: AppColors.feedbackError,
            ),
          );
        }
        return;
      }
    }
    try {
      final XFile? image = await AppMediaPicker.pickImage(source: source);
      if (image == null) return;

      final prepared = await ImageUploadCompressor.prepareForPreview(
        File(image.path),
      );
      if (!mounted) return;

      if (setAsPrimary) {
        setState(() {
          _avatarUrl = prepared.path;
          _isUploadingAvatar = true;
        });
        try {
          await _uploadImageAsPrimary(prepared);
        } finally {
          if (mounted) {
            setState(() => _isUploadingAvatar = false);
          }
        }
      } else {
        await _uploadImage(prepared);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to pick profile image',
        tag: 'ProfileEdit',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      final uploadedImage = await imageService.uploadImage(
        imageFile,
        type: 'gallery',
      );

      if (!mounted) return;
      setState(() {
        _images.add(uploadedImage);
      });
      await _syncProfileCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gallery photo added successfully'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.message}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageAsPrimary(File imageFile) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      final uploadedImage = await imageService.uploadImage(
        imageFile,
        type: 'primary',
      );
      await imageService.setPrimaryImage(
        uploadedImage.id,
        isProfilePicture: true,
      );

      if (!mounted) return;
      setState(() {
        _images =
            [
              ..._images.map((img) => img.copyWith(isPrimary: false)),
              uploadedImage.copyWith(isPrimary: true),
            ]..sort((a, b) {
              if (a.isPrimary != b.isPrimary) {
                return a.isPrimary ? -1 : 1;
              }
              return a.order.compareTo(b.order);
            });
        _avatarUrl = uploadedImage.avatarDisplayUrl;
      });
      await _syncProfileCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary photo updated'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload primary photo: ${e.message}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload primary photo: ${e.toString()}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    }
  }

  Future<void> _deleteImage(int imageId, int index) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      await imageService.deleteImage(imageId);

      if (!mounted) return;
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
      await _syncProfileCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image deleted successfully'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: ${e.message}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: ${e.toString()}'),
            backgroundColor: AppColors.feedbackError,
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
          final moved = _images.removeAt(index);
          _images.insert(0, moved);
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
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set primary image: ${e.toString()}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    }
  }

  Future<void> _reorderGalleryImages(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final previous = List<UserImage>.from(_images);
    final gallery = List<UserImage>.from(_galleryImages);
    final item = gallery.removeAt(oldIndex);
    gallery.insert(newIndex, item);

    final orderSlots = _galleryImages.map((img) => img.order).toList()..sort();
    final reorderedGallery = [
      for (var i = 0; i < gallery.length; i++)
        gallery[i].copyWith(order: orderSlots[i]),
    ];

    final nonGallery = _images.where((img) => img.type != 'gallery').toList();

    setState(() {
      _images = [...nonGallery, ...reorderedGallery];
    });

    try {
      final imageService = ref.read(imageServiceProvider);
      await imageService.reorderImages(_images.map((img) => img.id).toList());
      await _syncProfileCache();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _images = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder images: ${e.message}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _images = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder images: ${e.toString()}'),
            backgroundColor: AppColors.feedbackError,
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

  void _showImageSourceDialog({required bool setAsPrimary}) {
    ProfilePhotoSourceSheet.show(
      context,
      title: setAsPrimary ? 'Profile photo' : 'Add photo',
      onSourceSelected: (source) =>
          _pickImage(source, setAsPrimary: setAsPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ProfileEditPhotosSection.sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSettingsGroup(
          title: 'Profile photo',
          children: [
            Center(
              child: AvatarUpload(
                imageUrl: _avatarUrl,
                name: widget.name,
                size: 120.0,
                isLoading: _isUploadingAvatar,
                showPrimaryBadge: _avatarUrl != null && _avatarUrl!.isNotEmpty,
                onUpload: () => _showImageSourceDialog(setAsPrimary: true),
                onEdit: () => _showImageSourceDialog(setAsPrimary: true),
                onSetPrimary: _canPromoteAvatarToPrimary
                    ? _setPrimaryFromAvatar
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacingXL),
        PremiumSettingsGroup(
          title: 'Gallery',
          subtitle: 'Profiles with 3+ photos get 5× more matches',
          children: [
            ProfileImageEditor(
              key: ProfileEditPhotosSection.galleryKey,
              imageUrls: _galleryImages.map((img) => img.imageUrl).toList(),
              galleryOnly: true,
              maxImages: AppConstants.maxGalleryPhotos,
              onImageAdd: (_) => _showImageSourceDialog(setAsPrimary: false),
              onImageDelete: (galleryIndex) {
                final imageIndex = _imageIndexForGalleryIndex(galleryIndex);
                if (imageIndex != null) {
                  _deleteImage(_images[imageIndex].id, imageIndex);
                }
              },
              onImageReorder: _reorderGalleryImages,
            ),
          ],
        ),
      ],
    );
  }
}
