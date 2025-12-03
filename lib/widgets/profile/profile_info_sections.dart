// Widget: ProfileInfoSections
// Profile information sections
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Profile information sections widget
/// Displays user's interests, jobs, education, languages, etc.
/// Data structure based on API: user.interests, user.jobs, user.educations, etc.
class ProfileInfoSections extends ConsumerWidget {
  final List<String>? interests;
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

  const ProfileInfoSections({
    Key? key,
    this.interests,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Column(
      children: [
        if (interests != null && interests!.isNotEmpty)
          _buildSection(
            context: context,
            title: 'Interests',
            items: interests!,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        if (jobs != null && jobs!.isNotEmpty)
          _buildSection(
            context: context,
            title: 'Job',
            items: jobs!,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        if (educations != null && educations!.isNotEmpty)
          _buildSection(
            context: context,
            title: 'Education',
            items: educations!,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        if (languages != null && languages!.isNotEmpty)
          _buildSection(
            context: context,
            title: 'Languages',
            items: languages!,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        if (musicGenres != null && musicGenres!.isNotEmpty)
          _buildSection(
            context: context,
            title: 'Music',
            items: musicGenres!,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        if (relationGoals != null && relationGoals!.isNotEmpty)
          _buildSection(
            context: context,
            title: 'Looking for',
            items: relationGoals!,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        if (gender != null || preferredGenders != null)
          _buildSection(
            context: context,
            title: 'Gender',
            items: [
              if (gender != null) gender!,
              if (preferredGenders != null && preferredGenders!.isNotEmpty)
                'Interested in: ${preferredGenders!.join(', ')}',
            ],
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        if (height != null || weight != null || smoke != null || drink != null || gym != null)
          _buildDetailsSection(
            context: context,
            height: height,
            weight: weight,
            smoke: smoke,
            drink: drink,
            gym: gym,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<String> items,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: AppSpacing.spacingLG,
        right: AppSpacing.spacingLG,
        bottom: AppSpacing.spacingLG,
      ),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: items.map((item) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  item,
                  style: AppTypography.body.copyWith(
                    color: AppColors.accentPurple,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection({
    required BuildContext context,
    int? height,
    int? weight,
    bool? smoke,
    bool? drink,
    bool? gym,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final details = <String>[];
    if (height != null) details.add('${height}cm');
    if (weight != null) details.add('${weight}kg');
    if (smoke != null) details.add('Smoking: ${smoke! ? "Yes" : "No"}');
    if (drink != null) details.add('Drinking: ${drink! ? "Yes" : "No"}');
    if (gym != null) details.add('Gym: ${gym! ? "Yes" : "No"}');

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(
        left: AppSpacing.spacingLG,
        right: AppSpacing.spacingLG,
        bottom: AppSpacing.spacingLG,
      ),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: details.map((detail) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  detail,
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
