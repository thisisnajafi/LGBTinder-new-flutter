import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_grouped_list_card.dart';
import '../../../features/profile/providers/profile_wizard_provider.dart';
import '../../../features/profile/providers/wizard_reference_cache_provider.dart';
import '../../../features/reference_data/data/models/reference_item.dart';
import '../../../widgets/profile/edit/profile_section_editor.dart';
import '../profile_wizard_layout.dart';
import 'wizard_step_support.dart';

/// Step 5 — music genres + searchable interests.
class WizardStepInterests extends ConsumerStatefulWidget {
  const WizardStepInterests({super.key});

  static const pageKey = ValueKey<String>('wizard-step-interests');

  @override
  ConsumerState<WizardStepInterests> createState() =>
      _WizardStepInterestsState();
}

class _WizardStepInterestsState extends ConsumerState<WizardStepInterests> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final refs = ref.watch(wizardReferenceCacheProvider);
    final musicGenres =
        ref.watch(profileWizardProvider.select((s) => s.musicGenres));
    final selectedTitles = ref.watch(
      profileWizardProvider.select((s) => s.selectedInterestTitles),
    );

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Interests & Music',
        [
          refs.musicGenres.when(
            data: (genres) {
              return WizardStepSupport.groupedMultiSelectPicker(
                context: context,
                label: 'Music Genres',
                hint: 'Select music genres',
                selectedTitles:
                    WizardStepSupport.titleListFor(genres, musicGenres),
                onTap: () => WizardStepSupport.showMultiSelect(
                  context: context,
                  title: 'Select Music Genres',
                  items: genres,
                  selectedIds: musicGenres,
                  onSelected: (ids) => ref
                      .read(profileWizardProvider.notifier)
                      .setMusicGenres(ids),
                ),
                required: true,
                showDivider: false,
              );
            },
            loading: () => WizardStepSupport.loadingField(
              label: 'Music Genres',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Music Genres',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
          const AppGroupedRowSeparator(),
          refs.interests.when(
            data: (interests) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = interests.where((item) {
                if (query.isEmpty) return true;
                return item.title.toLowerCase().contains(query);
              }).toList();
              final interestTitles =
                  filtered.map((item) => item.title).toList();

              return ProfileWizardLayout.inset(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search interests',
                        hintText: 'Search interests',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AppSvgIcon(
                            assetPath: AppIcons.search,
                            size: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.spacingLG),
                    if (interestTitles.isEmpty)
                      Text(
                        'No interests found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      )
                    else
                      ProfileSectionEditor(
                        sectionTitle: 'Interests',
                        availableOptions: interestTitles,
                        selectedOptions: selectedTitles,
                        showSearch: false,
                        autoSave: true,
                        minSelections: 1,
                        maxSelections: 10,
                        onSave: (selected) {
                          final ids = selected
                              .map((title) {
                                final interest = interests.firstWhere(
                                  (item) => item.title == title,
                                  orElse: () =>
                                      ReferenceItem(id: -1, title: ''),
                                );
                                return interest.id != -1 ? interest.id : null;
                              })
                              .whereType<int>()
                              .toList();
                          ref.read(profileWizardProvider.notifier).setInterests(
                                titles: selected,
                                ids: ids,
                              );
                        },
                      ),
                  ],
                ),
              );
            },
            loading: () => WizardStepSupport.loadingField(
              label: 'Interests',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            error: (error, _) => WizardStepSupport.errorField(
              label: 'Interests',
              error: error,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
          ),
        ],
        first: true,
      ),
      ProfileWizardLayout.footnote(
        text: 'Pick at least one interest and your favorite music genres.',
      ),
    ]);
  }
}
