import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_list_view.dart';
import '../../../features/profile/providers/profile_wizard_provider.dart';
import '../profile_wizard_layout.dart';

/// Step 6 — extra gallery photos with a fixed-height [ListView.builder]
/// (PERF-PAGE-WIZARD-003).
class WizardStepGallery extends ConsumerWidget {
  const WizardStepGallery({
    super.key,
    required this.onPickPhotos,
  });

  static const pageKey = ValueKey<String>('wizard-step-gallery');

  final VoidCallback onPickPhotos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final files = ref.watch(
      profileWizardProvider.select((s) => s.additionalImageFiles),
    );
    final total = ref.watch(
      profileWizardProvider.select((s) => s.totalGalleryCount),
    );
    final full =
        ref.watch(profileWizardProvider.select((s) => s.galleryFull));
    const maxPhotos = AppConstants.maxGalleryPhotos;

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Additional Photos',
        [
          ProfileWizardLayout.inset(
            child: Column(
              children: [
                Text(
                  'Add more photos to your profile',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'You can add up to $maxPhotos photos. Select multiple from your gallery at once!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXL),
                if (files.isEmpty)
                  GestureDetector(
                    onTap: full ? null : onPickPhotos,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.spacingXXL),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusMD),
                      ),
                      child: Column(
                        children: [
                          AppSvgIcon(
                            assetPath: AppIcons.galleryAdd,
                            size: 60,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(height: AppSpacing.spacingMD),
                          Text(
                            'No additional photos yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingXS),
                          Text(
                            'Tap to add photos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _FixedHeightPhotoRows(
                    files: files,
                    onRemove: (index) => ref
                        .read(profileWizardProvider.notifier)
                        .removeGalleryAt(index),
                  ),
                const SizedBox(height: AppSpacing.spacingLG),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: full ? null : onPickPhotos,
                    icon: AppSvgIcon(
                      assetPath: AppIcons.galleryAdd,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      full
                          ? 'Maximum $maxPhotos photos'
                          : 'Add Photos ($total/$maxPhotos)',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        first: true,
      ),
      ProfileWizardLayout.footnote(
        text: 'Additional photos appear on your profile after setup.',
      ),
    ]);
  }
}

class _FixedHeightPhotoRows extends StatelessWidget {
  const _FixedHeightPhotoRows({
    required this.files,
    required this.onRemove,
  });

  final List<File> files;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;
    final columns = ResponsiveGrid.photoColumns(context);
    final rows = (files.length / columns).ceil().clamp(1, 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tile =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final height = rows * tile + (rows - 1) * spacing;
        return SizedBox(
          height: height,
          child: AppListView.builder(
            itemCount: rows,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, row) {
              return Padding(
                padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : spacing),
                child: SizedBox(
                  height: tile,
                  child: Row(
                    children: [
                      for (var col = 0; col < columns; col++) ...[
                        if (col > 0) const SizedBox(width: spacing),
                        Expanded(
                          child: _photoCell(row * columns + col),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _photoCell(int index) {
    if (index >= files.length) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          child: Image.file(
            files[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: AppSvgIcon(
                assetPath: AppIcons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
