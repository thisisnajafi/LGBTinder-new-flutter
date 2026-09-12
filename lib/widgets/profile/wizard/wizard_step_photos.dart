import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/spacing_constants.dart';
import '../../../core/widgets/app_grouped_list_card.dart';
import '../../../features/profile/providers/profile_wizard_provider.dart';
import '../../profile/avatar_upload.dart';
import '../profile_wizard_layout.dart';

/// Step 1 — primary profile photo (PERF-PAGE-WIZARD-001).
class WizardStepPhotos extends ConsumerWidget {
  const WizardStepPhotos({
    super.key,
    required this.onPickPhoto,
  });

  static const pageKey = ValueKey<String>('wizard-step-photos');

  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final avatarUrl =
        ref.watch(profileWizardProvider.select((s) => s.avatarUrl));
    final name = ref.watch(profileWizardProvider.select((s) => s.name));
    final hasPhoto =
        ref.watch(profileWizardProvider.select((s) => s.hasProfilePhoto));

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Profile Photo',
        [
          ProfileWizardLayout.inset(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.spacingSM),
                Center(
                  child: AvatarUpload(
                    imageUrl: avatarUrl,
                    name: name.isNotEmpty ? name : 'User',
                    size: 136,
                    onUpload: onPickPhoto,
                    onEdit: onPickPhoto,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingLG),
                Text(
                  hasPhoto ? 'Looking good!' : 'Add a profile photo',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXS),
                Text(
                  hasPhoto
                      ? 'This photo appears on discovery and in chat'
                      : 'Choose a clear photo that shows your face',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    height: 1.45,
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: AppSpacing.spacingMD),
                  const AppGroupedInfoTile(
                    label: 'Status',
                    value: 'Profile photo selected',
                    badge: 'Ready',
                    showDivider: false,
                  ),
                ],
                const SizedBox(height: AppSpacing.spacingSM),
              ],
            ),
          ),
        ],
        first: true,
      ),
      ProfileWizardLayout.footnote(
        text: 'Your primary photo is shown on discovery and in chat.',
      ),
    ]);
  }
}
