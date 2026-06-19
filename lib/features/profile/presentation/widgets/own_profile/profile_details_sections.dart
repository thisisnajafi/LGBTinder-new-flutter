import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/border_radius_constants.dart';
import '../../../../../core/theme/spacing_constants.dart';
import '../../../../../core/utils/app_icons.dart';
import '../../../../../core/widgets/profile_image_widget.dart';
import '../../../../../shared/models/user_tier.dart';
import '../../../../payments/data/models/subscription_plan.dart';
import '../../../widgets/tier_badge.dart';
import '../../../../../core/widgets/app_page_header.dart';
import '../../../../../core/widgets/premium/premium_design_system.dart';

/// Shared horizontal inset for profile scroll content (own + other user).
abstract final class ProfileContentLayout {
  static const double horizontalInset = AppPageHeader.horizontalPadding;
  static const EdgeInsets shellMargin =
      EdgeInsets.symmetric(horizontal: horizontalInset);
  static const EdgeInsets shellMarginNone = EdgeInsets.zero;
}

/// One attribute chip in the details grid.
class ProfileDetailChipData {
  final String iconPath;
  final String label;
  final String value;
  final Color accent;

  const ProfileDetailChipData({
    required this.iconPath,
    required this.label,
    required this.value,
    this.accent = AppColors.accentViolet,
  });
}

// ─── Photos ────────────────────────────────────────────────────────────────

class PremiumPhotosSection extends StatelessWidget {
  const PremiumPhotosSection({
    super.key,
    required this.imageUrls,
    required this.totalCount,
    required this.onEdit,
    required this.onAdd,
    required this.onPhotoTap,
    this.shellMargin,
  });

  final List<String> imageUrls;
  final int totalCount;
  final VoidCallback onEdit;
  final VoidCallback onAdd;
  final void Function(int index) onPhotoTap;
  final EdgeInsets? shellMargin;

  @override
  Widget build(BuildContext context) {
    final previewCount = AppConstants.profilePhotoGridPreview;
    final hasPhotos = imageUrls.isNotEmpty;
    final display = imageUrls.take(previewCount).toList();
    final itemCount = hasPhotos ? display.length + 1 : 3;

    return PremiumProfileShell(
      margin: shellMargin ?? ProfileContentLayout.shellMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSectionHeader(
            title: 'Gallery',
            subtitle: hasPhotos
                ? '$totalCount photo${totalCount == 1 ? '' : 's'} · Drag to reorder in edit'
                : 'Profiles with 3+ photos get 5× more matches',
            actionLabel: hasPhotos ? 'Edit' : null,
            onAction: hasPhotos ? onEdit : null,
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.82,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (!hasPhotos) {
                return _AddPhotoTile(onTap: onAdd);
              }
              if (index < display.length) {
                final isPrimary = index == 0;
                return PremiumTapScale(
                  onTap: () => onPhotoTap(index),
                  semanticLabel: 'Photo ${index + 1}',
                  child: _PhotoTile(url: display[index], isPrimary: isPrimary),
                );
              }
              return _AddPhotoTile(onTap: onAdd);
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.url, required this.isPrimary});

  final String url;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        gradient: isPrimary ? AppColors.brandGradient : null,
        border: isPrimary
            ? null
            : Border.all(
                color: AppColors.accentViolet.withValues(alpha: 0.15),
              ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isPrimary ? 2.5 : 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            isPrimary ? AppRadius.radiusLG - 2 : AppRadius.radiusLG,
          ),
          child: ProfileImageWidget(imageUrl: url, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumTapScale(
      onTap: onTap,
      semanticLabel: 'Add photo',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: 0.35),
            width: 1.5,
          ),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.tintVioletLight.withValues(alpha: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.camera,
              size: 26,
              color: AppColors.accentViolet,
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accentViolet,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Personality (bio + prompts) ───────────────────────────────────────────

class PremiumPersonalitySection extends StatelessWidget {
  const PremiumPersonalitySection({
    super.key,
    required this.bio,
    required this.conversationStarters,
    this.onEdit,
    this.sectionTitle = 'Personality',
    this.sectionSubtitle = 'Let your authentic self shine',
    this.quoteBio = true,
    this.shellMargin,
  });

  final String? bio;
  final List<String> conversationStarters;
  final VoidCallback? onEdit;
  final String sectionTitle;
  final String? sectionSubtitle;
  final bool quoteBio;
  final EdgeInsets? shellMargin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trimmed = bio?.trim() ?? '';
    final hasBio = trimmed.isNotEmpty;

    return PremiumProfileShell(
      margin: shellMargin ?? ProfileContentLayout.shellMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSectionHeader(
            title: sectionTitle,
            subtitle: sectionSubtitle,
            onEdit: onEdit,
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusLG),
              color: isDark
                  ? AppColors.cardBackgroundDark
                  : AppColors.cardBackgroundLight,
              border: Border.all(
                color: AppColors.accentPink.withValues(alpha: 0.15),
              ),
            ),
            child: hasBio
                ? Text(
                    quoteBio ? '"$trimmed"' : trimmed,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                      fontStyle: quoteBio ? FontStyle.italic : FontStyle.normal,
                    ),
                  )
                : PremiumTapScale(
                    onTap: onEdit ?? () {},
                    semanticLabel: 'Add bio',
                    child: Row(
                      children: [
                        AppSvgIcon(
                          assetPath: AppIcons.edit,
                          size: 22,
                          color: AppColors.accentPink,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Write a bio that shows who you are — humor, passions, what you are looking for.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (conversationStarters.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spacingMD),
            Text(
              'Conversation starters',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accentViolet,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            ...conversationStarters.map(
              (starter) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.message,
                        size: 18,
                        color: AppColors.feedbackInfo,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          starter,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Details grid ──────────────────────────────────────────────────────────

class PremiumDetailsGridSection extends StatelessWidget {
  const PremiumDetailsGridSection({
    super.key,
    required this.chips,
    this.onEdit,
    this.sectionTitle = 'About me',
    this.sectionSubtitle = 'The details that help you match better',
    this.shellMargin,
  });

  final List<ProfileDetailChipData> chips;
  final VoidCallback? onEdit;
  final String sectionTitle;
  final String? sectionSubtitle;
  final EdgeInsets? shellMargin;

  @override
  Widget build(BuildContext context) {
    return PremiumProfileShell(
      margin: shellMargin ?? ProfileContentLayout.shellMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSectionHeader(
            title: sectionTitle,
            subtitle: sectionSubtitle,
            onEdit: onEdit,
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          if (chips.isEmpty)
            PremiumTapScale(
              onTap: onEdit ?? () {},
              semanticLabel: 'Add profile details',
              child: _EmptyPrompt(
                icon: AppIcons.userEdit,
                text: 'Add location, work, goals & more',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final w = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: chips
                      .map((c) => SizedBox(width: w, child: _DetailChip(data: c)))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.data});

  final ProfileDetailChipData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: data.accent.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.accent.withValues(alpha: 0.15),
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: data.iconPath,
                size: 18,
                color: data.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  data.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(assetPath: icon, size: 20, color: AppColors.accentViolet),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Interests ─────────────────────────────────────────────────────────────

class PremiumInterestsSection extends StatelessWidget {
  const PremiumInterestsSection({
    super.key,
    required this.labels,
    this.onEdit,
    this.shellMargin,
  });

  final List<String> labels;
  final VoidCallback? onEdit;
  final EdgeInsets? shellMargin;

  static const _accents = [
    AppColors.accentViolet,
    AppColors.accentPink,
    AppColors.feedbackInfo,
    AppColors.feedbackSuccess,
    AppColors.warningYellow,
  ];

  @override
  Widget build(BuildContext context) {
    return PremiumProfileShell(
      margin: shellMargin ?? ProfileContentLayout.shellMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSectionHeader(
            title: 'Interests',
            subtitle: labels.isEmpty
                ? 'Shared interests spark better conversations'
                : '${labels.length} passion${labels.length == 1 ? '' : 's'}',
            onEdit: onEdit,
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          if (labels.isEmpty)
            PremiumTapScale(
              onTap: onEdit ?? () {},
              semanticLabel: 'Add interests',
              child: const _EmptyPrompt(
                icon: AppIcons.heart,
                text: 'Add interests to find people who get you',
              ),
            )
          else ...[
            _InterestGroup(
              title: 'Your vibe',
              labels: labels.take(12).toList(),
              startAccentIndex: 0,
            ),
            if (labels.length > 12) ...[
              const SizedBox(height: AppSpacing.spacingMD),
              _InterestGroup(
                title: 'More interests',
                labels: labels.skip(12).toList(),
                startAccentIndex: 2,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InterestGroup extends StatelessWidget {
  const _InterestGroup({
    required this.title,
    required this.labels,
    required this.startAccentIndex,
  });

  final String title;
  final List<String> labels;
  final int startAccentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accentViolet,
          ),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < labels.length; i++)
              _GradientInterestPill(
                label: labels[i],
                accent: PremiumInterestsSection._accents[
                    (startAccentIndex + i) %
                        PremiumInterestsSection._accents.length],
              ),
          ],
        ),
      ],
    );
  }
}

class _GradientInterestPill extends StatelessWidget {
  const _GradientInterestPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
      ),
    );
  }
}

// ─── Account hub ───────────────────────────────────────────────────────────

class PremiumAccountHubSection extends StatelessWidget {
  const PremiumAccountHubSection({super.key, required this.actions});

  final List<ProfileHubActionData> actions;

  @override
  Widget build(BuildContext context) {
    return PremiumHubGridSection(
      title: 'Account & trust',
      subtitle: 'Manage your profile, privacy, and premium tools',
      actions: actions,
    );
  }
}

// ─── Membership ────────────────────────────────────────────────────────────

class PremiumMembershipSection extends StatelessWidget {
  const PremiumMembershipSection({
    super.key,
    required this.tier,
    required this.subscription,
    required this.onUpgrade,
    required this.onManage,
  });

  final UserTier tier;
  final SubscriptionStatus? subscription;
  final VoidCallback onUpgrade;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBasid = tier == UserTier.basid;

    final tierLabel = switch (tier) {
      UserTier.golden => 'Golden',
      UserTier.silder => 'Silder',
      UserTier.basid => 'Basid',
    };

    final benefits = switch (tier) {
      UserTier.golden => const [
          'Unlimited likes',
          'See who liked you',
          'Profile boost',
          'Passport mode',
        ],
      UserTier.silder => const [
          'Unlimited likes',
          'Advanced filters',
          'Video calls',
        ],
      UserTier.basid => const [
          'Unlimited likes',
          'See who liked you',
          'Boost & priority',
          'Ad-free experience',
        ],
    };

    final expiry = subscription?.endDate ?? subscription?.nextBillingDate;
    final expiryText = expiry != null
        ? '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusXL),
          gradient: isBasid
              ? AppColors.brandGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF3D2A5C),
                          const Color(0xFF2A1F3D),
                          const Color(0xFF1A1528),
                        ]
                      : [
                          AppColors.tintVioletLight,
                          Colors.white,
                          AppColors.tintRoseLight,
                        ],
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TierBadge(tier: tier, compact: true),
                  const SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBasid ? 'Unlock Premium' : '$tierLabel Membership',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isBasid || isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (!isBasid && expiryText != null)
                          Text(
                            'Active until $expiryText',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacingMD),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: benefits
                    .map(
                      (b) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: (isBasid || isDark
                                  ? Colors.white
                                  : AppColors.accentViolet)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: (isBasid || isDark
                                    ? Colors.white
                                    : AppColors.accentViolet)
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          b,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isBasid || isDark
                                ? Colors.white
                                : AppColors.accentViolet,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.spacingMD),
              FilledButton(
                onPressed: isBasid ? onUpgrade : onManage,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isBasid ? Colors.white : AppColors.accentPink,
                  foregroundColor:
                      isBasid ? AppColors.accentViolet : Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                ),
                child: Text(
                  isBasid ? 'View plans' : 'Manage membership',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Build conversation starters from profile context.
List<String> buildConversationStarters({
  String? city,
  required List<String> interests,
  String? job,
}) {
  final starters = <String>[];
  if (interests.isNotEmpty) {
    starters.add('Ask me about ${interests.first}');
  }
  if (city != null && city.isNotEmpty) {
    starters.add('Best date spot in $city? I have opinions.');
  }
  if (job != null && job.isNotEmpty) {
    starters.add('I work in $job — always up for career chat');
  }
  starters.add('Swipe right if you love deep conversations');
  if (interests.length > 1) {
    starters.add('We should talk about ${interests[1]}');
  }
  return starters.take(4).toList();
}

/// Compose detail chips from profile fields.
List<ProfileDetailChipData> buildProfileDetailChips({
  String? location,
  String? job,
  String? education,
  int? height,
  String? gender,
  List<String> relationGoals = const [],
  List<String> languages = const [],
  bool? smoke,
  bool? drink,
  bool? gym,
}) {
  final chips = <ProfileDetailChipData>[];
  void add(String icon, String label, String value, [Color? accent]) {
    chips.add(ProfileDetailChipData(
      iconPath: icon,
      label: label,
      value: value,
      accent: accent ?? AppColors.accentViolet,
    ));
  }

  if (location != null && location.isNotEmpty) {
    add(AppIcons.location, 'Location', location, AppColors.accentPink);
  }
  if (job != null && job.isNotEmpty) {
    add(AppIcons.getIconPath('briefcase'), 'Work', job, AppColors.feedbackInfo);
  }
  if (education != null && education.isNotEmpty) {
    add(
      AppIcons.getIconPath('teacher'),
      'Education',
      education,
      AppColors.accentViolet,
    );
  }
  if (height != null) {
    add(AppIcons.getIconPath('ruler'), 'Height', '$height cm');
  }
  if (gender != null && gender.isNotEmpty) {
    add(AppIcons.getIconPath('profile-circle'), 'Identity', gender);
  }
  if (relationGoals.isNotEmpty) {
    add(
      AppIcons.heart,
      'Looking for',
      relationGoals.join(', '),
      AppColors.accentPink,
    );
  }
  if (languages.isNotEmpty) {
    add(
      AppIcons.getIconPath('translate'),
      'Languages',
      languages.join(', '),
      AppColors.feedbackSuccess,
    );
  }
  if (smoke != null) {
    add(
      AppIcons.getIconPath('cloud'),
      'Smoking',
      smoke ? 'Yes' : 'No',
    );
  }
  if (drink != null) {
    add(
      AppIcons.getIconPath('glass'),
      'Drinking',
      drink ? 'Yes' : 'No',
    );
  }
  if (gym != null) {
    add(
      AppIcons.getIconPath('weight'),
      'Fitness',
      gym ? 'Active' : 'Sometimes',
      AppColors.warningYellow,
    );
  }
  return chips;
}
