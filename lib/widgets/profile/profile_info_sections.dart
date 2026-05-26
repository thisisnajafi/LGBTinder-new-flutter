// Widget: ProfileInfoSections — grouped info pills
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../features/profile/widgets/profile_info_pill.dart';
import '../../features/profile/widgets/interest_chip_list.dart';

class ProfileInfoSections extends ConsumerWidget {
  final List<String>? interests;
  final Set<String>? sharedInterests;
  final List<String>? jobs;
  final List<String>? educations;
  final List<String>? languages;
  final List<String>? musicGenres;
  final List<String>? relationGoals;
  final String? gender;
  final List<String>? preferredGenders;
  final int? height;
  final int? weight;
  final bool? smoke;
  final bool? drink;
  final bool? gym;
  final String? location;
  final String? distance;

  const ProfileInfoSections({
    super.key,
    this.interests,
    this.sharedInterests,
    this.jobs,
    this.educations,
    this.languages,
    this.musicGenres,
    this.relationGoals,
    this.gender,
    this.preferredGenders,
    this.height,
    this.weight,
    this.smoke,
    this.drink,
    this.gym,
    this.location,
    this.distance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (interests != null && interests!.isNotEmpty)
          InterestChipList(
            interests: interests!,
            sharedInterests: sharedInterests,
          ),
        if (location != null || distance != null)
          _Section(
            title: 'Basics',
            child: Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: [
                if (distance != null)
                  ProfileInfoPill(iconPath: AppIcons.location, label: distance!),
                if (location != null)
                  ProfileInfoPill(iconPath: AppIcons.getIconPath('global'), label: location!),
                if (gender != null)
                  ProfileInfoPill(iconPath: AppIcons.userOutline, label: gender!),
              ],
            ),
          ),
        if (jobs != null && jobs!.isNotEmpty)
          _Section(
            title: 'Work',
            child: Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: jobs!
                  .map((j) => ProfileInfoPill(iconPath: AppIcons.getIconPath('briefcase'), label: j))
                  .toList(),
            ),
          ),
        if (educations != null && educations!.isNotEmpty)
          _Section(
            title: 'Education',
            child: Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: educations!
                  .map((e) => ProfileInfoPill(iconPath: AppIcons.getIconPath('book'), label: e))
                  .toList(),
            ),
          ),
        if (languages != null && languages!.isNotEmpty)
          _Section(
            title: 'Languages',
            child: Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: languages!
                  .map((l) => ProfileInfoPill(iconPath: AppIcons.getIconPath('global'), label: l))
                  .toList(),
            ),
          ),
        if (musicGenres != null && musicGenres!.isNotEmpty)
          _Section(
            title: 'Music',
            child: Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: musicGenres!
                  .map((m) => ProfileInfoPill(iconPath: AppIcons.getIconPath('music'), label: m))
                  .toList(),
            ),
          ),
        if (relationGoals != null && relationGoals!.isNotEmpty)
          _Section(
            title: 'Looking for',
            child: Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: relationGoals!
                  .map((g) => ProfileInfoPill(iconPath: AppIcons.heartOutline, label: g))
                  .toList(),
            ),
          ),
        if (preferredGenders != null && preferredGenders!.isNotEmpty)
          _Section(
            title: 'Interested in',
            child: Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: preferredGenders!
                  .map((g) => ProfileInfoPill(iconPath: AppIcons.getIconPath('people'), label: g))
                  .toList(),
            ),
          ),
        if (height != null || weight != null || smoke != null || drink != null || gym != null)
          _Section(
            title: 'Lifestyle',
            child: Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: [
                if (height != null)
                  ProfileInfoPill(
                    iconPath: AppIcons.getIconPath('weight'),
                    label: '${height}cm',
                  ),
                if (weight != null)
                  ProfileInfoPill(
                    iconPath: AppIcons.getIconPath('weight'),
                    label: '${weight}kg',
                  ),
                if (smoke != null)
                  ProfileInfoPill(
                    iconPath: AppIcons.getIconPath('cloud'),
                    label: 'Smoking: ${smoke! ? 'Yes' : 'No'}',
                  ),
                if (drink != null)
                  ProfileInfoPill(
                    iconPath: AppIcons.getIconPath('cup'),
                    label: 'Drinking: ${drink! ? 'Yes' : 'No'}',
                  ),
                if (gym != null)
                  ProfileInfoPill(
                    iconPath: AppIcons.getIconPath('activity'),
                    label: 'Gym: ${gym! ? 'Yes' : 'No'}',
                  ),
              ],
            ),
          ),
        SizedBox(height: AppSpacing.spacingMD),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.spacingLG,
        0,
        AppSpacing.spacingLG,
        AppSpacing.spacingLG,
      ),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          child,
        ],
      ),
    );
  }
}
