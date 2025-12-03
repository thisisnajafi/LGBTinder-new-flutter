// Widget: MediaPickerBottomSheet
// Bottom sheet for media selection
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modals/bottom_sheet_custom.dart';
import 'media_picker.dart';

/// Media picker bottom sheet widget
/// Wrapper for media picker in a bottom sheet
class MediaPickerBottomSheet extends ConsumerWidget {
  final Function(String?)? onImageSelected;
  final Function(String?)? onVideoSelected;
  final Function(String?)? onFileSelected;

  const MediaPickerBottomSheet({
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
      child: MediaPickerBottomSheet(
        onImageSelected: onImageSelected,
        onVideoSelected: onVideoSelected,
        onFileSelected: onFileSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaPicker(
      onImageSelected: (path) {
        Navigator.of(context).pop();
        onImageSelected?.call(path);
      },
      onVideoSelected: (path) {
        Navigator.of(context).pop();
        onVideoSelected?.call(path);
      },
      onFileSelected: (path) {
        Navigator.of(context).pop();
        onFileSelected?.call(path);
      },
    );
  }
}
