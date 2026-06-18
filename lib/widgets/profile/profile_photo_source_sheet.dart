import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_action_bottom_sheet.dart';

/// Settings-style bottom sheet for choosing a profile photo source.
class ProfilePhotoSourceSheet extends StatelessWidget {
  final void Function(ImageSource source) onSourceSelected;
  final String title;
  final String galleryLabel;
  final String gallerySubtitle;

  const ProfilePhotoSourceSheet({
    super.key,
    required this.onSourceSelected,
    this.title = 'Profile photo',
    this.galleryLabel = 'Choose from gallery',
    this.gallerySubtitle = 'Pick an existing photo',
  });

  static List<AppActionSheetItem> _items(
    BuildContext context, {
    required void Function(ImageSource source) onSourceSelected,
    required String galleryLabel,
    required String gallerySubtitle,
  }) {
    final theme = Theme.of(context);
    return [
      AppActionSheetItem(
        iconPath: AppIcons.gallery,
        label: galleryLabel,
        subtitle: gallerySubtitle,
        iconColor: theme.colorScheme.primary,
        onTap: () {
          Navigator.pop(context);
          onSourceSelected(ImageSource.gallery);
        },
      ),
      AppActionSheetItem(
        iconPath: AppIcons.camera,
        label: 'Take a photo',
        subtitle: 'Use your camera now',
        iconColor: theme.colorScheme.secondary,
        onTap: () {
          Navigator.pop(context);
          onSourceSelected(ImageSource.camera);
        },
      ),
    ];
  }

  static Future<void> show(
    BuildContext context, {
    required void Function(ImageSource source) onSourceSelected,
    String title = 'Profile photo',
    String galleryLabel = 'Choose from gallery',
    String gallerySubtitle = 'Pick an existing photo',
  }) {
    return AppActionBottomSheet.show(
      context: context,
      title: title,
      actions: _items(
        context,
        onSourceSelected: onSourceSelected,
        galleryLabel: galleryLabel,
        gallerySubtitle: gallerySubtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetShell(
      title: title,
      actions: _items(
        context,
        onSourceSelected: onSourceSelected,
        galleryLabel: galleryLabel,
        gallerySubtitle: gallerySubtitle,
      ),
    );
  }
}
