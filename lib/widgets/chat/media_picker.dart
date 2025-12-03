// Widget: MediaPicker
// Media picker component
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../modals/bottom_sheet_custom.dart';

/// Media picker widget
/// Allows users to pick images, videos, or files
class MediaPicker extends ConsumerStatefulWidget {
  final Function(String? imagePath)? onImageSelected;
  final Function(String? videoPath)? onVideoSelected;
  final Function(String? filePath)? onFileSelected;

  const MediaPicker({
    Key? key,
    this.onImageSelected,
    this.onVideoSelected,
    this.onFileSelected,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    Function(String?)? onImageSelected,
    Function(String?)? onVideoSelected,
    Function(String?)? onFileSelected,
  }) {
    BottomSheetCustom.show(
      context: context,
      title: 'Select Media',
      child: MediaPicker(
        onImageSelected: onImageSelected,
        onVideoSelected: onVideoSelected,
        onFileSelected: onFileSelected,
      ),
    );
  }

  @override
  ConsumerState<MediaPicker> createState() => _MediaPickerState();
}

class _MediaPickerState extends ConsumerState<MediaPicker> {
  void _pickImage() {
    // TODO: Implement image picker
    widget.onImageSelected?.call(null);
    Navigator.of(context).pop();
  }

  void _pickVideo() {
    // TODO: Implement video picker
    widget.onVideoSelected?.call(null);
    Navigator.of(context).pop();
  }

  void _pickFile() {
    // TODO: Implement file picker
    widget.onFileSelected?.call(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOption(
            context: context,
            icon: Icons.image,
            label: 'Photo',
            onTap: _pickImage,
            textColor: textColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildOption(
            context: context,
            icon: Icons.videocam,
            label: 'Video',
            onTap: _pickVideo,
            textColor: textColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildOption(
            context: context,
            icon: Icons.insert_drive_file,
            label: 'File',
            onTap: _pickFile,
            textColor: textColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accentPurple, size: 32),
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
