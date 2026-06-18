import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cache/session_cache_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/border_radius_constants.dart';
import '../../../../../core/theme/spacing_constants.dart';
import '../../../../../core/utils/app_icons.dart';
import '../../../../../core/widgets/app_grouped_list_card.dart';
import '../../../../../core/widgets/profile_image_widget.dart';
import '../../../../payments/data/models/subscription_plan.dart';
import '../../../../payments/providers/payment_providers.dart';
import '../../../data/models/user_image.dart';
import '../../../data/models/user_profile.dart';
import '../../../../reference_data/data/models/reference_item.dart';
import '../../../../reference_data/providers/reference_data_providers.dart';
import '../../../../settings/presentation/screens/matching_preferences_screen.dart';
import '../../../../../pages/profile_edit_page.dart';
import '../../../../../screens/profile/profile_verification_screen.dart';
import '../../../../../shared/models/user_tier.dart';
import '../../../../../shared/providers/user_tier_provider.dart';
import 'profile_completeness_utils.dart';

/// Own-profile scroll layout (dating-app standard).
class OwnProfileView extends ConsumerWidget {
  final UserProfile profile;
  final VoidCallback onViewProfile;
  final VoidCallback onEditPhotos;
  final VoidCallback onAddPhoto;
  final void Function(int index) onPhotoTap;

  const OwnProfileView({
    super.key,
    required this.profile,
    required this.onViewProfile,
    required this.onEditPhotos,
    required this.onAddPhoto,
    required this.onPhotoTap,
  });

  static const double _hPad = 20;
  static const double _sectionGap = AppSpacing.spacingXL;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullName = profile.lastName.trim().isEmpty
        ? profile.firstName
        : '${profile.firstName} ${profile.lastName}';
    final age = _age(profile);
    final avatarUrl = profile.images?.isNotEmpty == true
        ? profile.images!.first.imageUrl
        : null;
    final isVerified = profile.isVerified == true;

    final UserTier tier = ref.watch(userTierProvider);
    final superlikes = ref.watch(superlikesRemainingProvider);
    final completeness = computeProfileCompleteness(profile);

    final sessionCache = ref.watch(sessionDataCacheServiceProvider);
    final cachedSub = sessionCache.getSubscriptionStatusSync();
    final subAsync = ref.watch(subscriptionStatusProvider);
    final subscription = cachedSub ?? subAsync.valueOrNull;

    final interestsRef = ref.watch(interestsProvider).valueOrNull ?? const [];
    final jobsRef = ref.watch(jobsProvider).valueOrNull ?? const [];
    final educationsRef = ref.watch(educationLevelsProvider).valueOrNull ?? const [];
    final gendersRef = ref.watch(gendersProvider).valueOrNull ?? const [];

    final interestLabels = _resolveLabels(
      profile.interestTitles,
      profile.interests,
      interestsRef,
    );
    final jobLabel = _firstLabel(
      profile.jobTitles,
      profile.jobs,
      jobsRef,
    );
    final educationLabel = _firstLabel(
      profile.educationTitles,
      profile.educations,
      educationsRef,
    );
    final genderLabel = profile.gender ?? _labelForId(profile.genderId, gendersRef);
    final locationLabel = _locationLabel(profile);

    final photos = profile.images ?? [];
    final displayPhotos = photos.take(6).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageHeader(context, onViewProfile),
              const SizedBox(height: AppSpacing.spacingLG),
              _identityBlock(
                context,
                fullName: fullName,
                avatarUrl: avatarUrl,
                age: age,
                isVerified: isVerified,
                tier: tier,
                onEditPhoto: onEditPhotos,
              ),
              if (!completeness.isComplete) ...[
                const SizedBox(height: _sectionGap),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
                  child: _completenessCard(
                    context,
                    completeness: completeness,
                    onComplete: () => _openEdit(context),
                  ),
                ),
              ],
              if (superlikes != null) ...[
                const SizedBox(height: _sectionGap),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
                  child: _superlikesSection(
                    context,
                    superlikes: superlikes,
                  ),
                ),
              ],
              const SizedBox(height: _sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _photosSection(
                  context,
                  photos: displayPhotos,
                  totalCount: photos.length,
                  onEdit: onEditPhotos,
                  onAdd: onAddPhoto,
                  onPhotoTap: onPhotoTap,
                ),
              ),
              const SizedBox(height: _sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _bioSection(context, bio: profile.profileBio),
              ),
              const SizedBox(height: _sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _detailsSection(
                  context,
                  location: locationLabel,
                  job: jobLabel,
                  education: educationLabel,
                  height: profile.height,
                  gender: genderLabel,
                ),
              ),
              const SizedBox(height: _sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _interestsSection(context, labels: interestLabels),
              ),
              const SizedBox(height: _sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _profileActions(
                  context,
                  isVerified: isVerified,
                  tier: tier,
                ),
              ),
              const SizedBox(height: _sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _subscriptionCard(
                  context,
                  tier: tier,
                  subscription: subscription,
                ),
              ),
              const SizedBox(height: AppSpacing.spacingXXL),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pageHeader(BuildContext context, VoidCallback onViewProfile) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, AppSpacing.spacingSM, _hPad, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(
            onPressed: onViewProfile,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
            ),
            child: Text(
              'View profile',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityBlock(
    BuildContext context, {
    required String fullName,
    required String? avatarUrl,
    required int? age,
    required bool isVerified,
    required UserTier tier,
    required VoidCallback onEditPhoto,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    const avatarSize = 92.0;
    const cameraTapSize = 44.0;
    const verifiedBadgeSize = 22.0;
    const ageBadgeHalfHeight = 10.0;

    return Column(
      children: [
        SizedBox(
          width: avatarSize,
          height: avatarSize + ageBadgeHalfHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 2.5),
                ),
                child: ClipOval(
                  child: ProfileImageWidget(
                    imageUrl: avatarUrl,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (age != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: avatarSize - ageBadgeHalfHeight,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      ),
                      child: Text(
                        '$age',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isVerified)
                Positioned(
                  right: -verifiedBadgeSize / 2,
                  bottom: -verifiedBadgeSize / 2,
                  child: Container(
                    width: verifiedBadgeSize,
                    height: verifiedBadgeSize,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: primary, width: 1.5),
                    ),
                    child: Center(
                      child: AppSvgIcon(
                        assetPath: AppIcons.getIconPath('tick-circle'),
                        size: 13,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: -cameraTapSize / 2,
                right: -cameraTapSize / 2,
                child: Semantics(
                  label: 'Change profile photo',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onEditPhoto,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: cameraTapSize,
                        height: cameraTapSize,
                        child: Center(
                          child: _CameraOverlayButton(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spacingMD),
        Text(
          fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.spacingXS),
        if (tier == UserTier.basid)
          OutlinedButton(
            onPressed: () => context.pushNamed('subscription-plans'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 36),
              side: BorderSide(color: primary),
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Upgrade to Premium',
              style: theme.textTheme.labelSmall,
            ),
          )
        else
          _tierPill(context, tier),
      ],
    );
  }

  Widget _tierPill(BuildContext context, UserTier tier) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isGolden = tier == UserTier.golden;
    final label = tier == UserTier.silder ? 'Silder' : 'Golden';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGolden
            ? AppColors.warningYellow.withValues(alpha: 0.15)
            : primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: isGolden ? AppColors.warningYellow : primary,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isGolden ? AppColors.warningYellow : primary,
        ),
      ),
    );
  }

  Widget _completenessCard(
    BuildContext context, {
    required ProfileCompletenessResult completeness,
    required VoidCallback onComplete,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: _CompletenessArcPainter(
                progress: completeness.percent / 100,
                trackColor: primary.withValues(alpha: 0.15),
                arcColor: primary,
              ),
              child: Center(
                child: Text(
                  '${completeness.percent}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (completeness.firstTip != null)
                  Text(
                    completeness.firstTip!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                const SizedBox(height: AppSpacing.spacingSM),
                OutlinedButton(
                  onPressed: onComplete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: Text('Complete now', style: theme.textTheme.labelSmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _superlikesSection(
    BuildContext context, {
    required int superlikes,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.30), width: 0.5),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            assetPath: AppIcons.getIconPath('star'),
            size: 18,
            color: primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Superlikes remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Text(
            '$superlikes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onEditIcon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              actionLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        else if (onEditIcon != null)
          Semantics(
            button: true,
            label: 'Edit $title',
            child: InkWell(
              onTap: onEditIcon,
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.getIconPath('edit'),
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _photosSection(
    BuildContext context, {
    required List<UserImage> photos,
    required int totalCount,
    required VoidCallback onEdit,
    required VoidCallback onAdd,
    required void Function(int index) onPhotoTap,
  }) {
    final theme = Theme.of(context);
    final hasPhotos = photos.isNotEmpty;
    final itemCount = hasPhotos ? photos.length.clamp(0, 6) + 1 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          context,
          title: 'My Photos',
          actionLabel: hasPhotos ? 'Edit' : null,
          onAction: hasPhotos ? onEdit : null,
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (!hasPhotos) {
              return _addPhotoTile(context, onAdd);
            }
            if (index < photos.length) {
              final url = photos[index].imageUrl;
              return GestureDetector(
                onTap: () => onPhotoTap(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ProfileImageWidget(
                    imageUrl: url,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
            return _addPhotoTile(context, onAdd);
          },
        ),
        if (totalCount > 6)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.spacingSM),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onEdit,
                child: Text(
                  'See all',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _addPhotoTile(BuildContext context, VoidCallback onAdd) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(assetPath: AppIcons.camera, size: 24, color: muted),
            const SizedBox(height: 6),
            Text('Add photo', style: theme.textTheme.labelSmall?.copyWith(color: muted)),
          ],
        ),
      ),
    );
  }

  Widget _bioSection(BuildContext context, {String? bio}) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest;
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);
    final trimmed = bio?.trim() ?? '';
    final hasBio = trimmed.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          context,
          title: 'About me',
          onEditIcon: () => _openEdit(context),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        Material(
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: border, width: 0.5),
          ),
          child: InkWell(
            onTap: hasBio ? null : () => _openEdit(context),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: hasBio
                  ? Text(
                      trimmed,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppSvgIcon(
                          assetPath: AppIcons.getIconPath('edit'),
                          size: 18,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add a bio to attract more matches',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsSection(
    BuildContext context, {
    String? location,
    String? job,
    String? education,
    int? height,
    String? gender,
  }) {
    final theme = Theme.of(context);
    final pills = <Widget>[];
    if (location != null) {
      pills.add(_infoPill(context, AppIcons.location, location));
    }
    if (job != null) pills.add(_infoPill(context, AppIcons.getIconPath('briefcase'), job));
    if (education != null) {
      pills.add(_infoPill(context, AppIcons.getIconPath('teacher'), education));
    }
    if (height != null) {
      pills.add(_infoPill(context, AppIcons.getIconPath('ruler'), '${height} cm'));
    }
    if (gender != null && gender.isNotEmpty) {
      // TODO: pronouns field not on UserProfile — showing gender for now
      pills.add(_infoPill(context, AppIcons.getIconPath('woman'), gender));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          context,
          title: 'My details',
          onEditIcon: () => _openEdit(context),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        if (pills.isEmpty)
          _emptyDetailsTile(context)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pills,
          ),
      ],
    );
  }

  Widget _infoPill(BuildContext context, String iconPath, String text) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest;
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(assetPath: iconPath, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDetailsTile(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _openEdit(context),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                assetPath: AppIcons.getIconPath('edit'),
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 8),
              Text(
                'Add details',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _interestsSection(BuildContext context, {required List<String> labels}) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          context,
          title: 'Interests',
          onEditIcon: () => _openEdit(context),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        if (labels.isEmpty)
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
                width: 0.5,
              ),
            ),
            child: InkWell(
              onTap: () => _openEdit(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.getIconPath('edit'),
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add your interests to find better matches',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels.map((label) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  border: Border.all(color: primary.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: primary,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _profileActions(
    BuildContext context, {
    required bool isVerified,
    required UserTier tier,
  }) {
    final theme = Theme.of(context);
    final isBasid = tier == UserTier.basid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.spacingXS, bottom: AppSpacing.spacingSM),
          child: Text(
            'My profile',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              AppGroupedListTile(
                iconPath: AppIcons.userEdit,
                label: 'Edit profile',
                onTap: () => _openEdit(context),
              ),
              AppGroupedListTile(
                iconPath: AppIcons.verify,
                label: 'Verification',
                onTap: () {
                  // TODO: named route for profile verification when added to app_router
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileVerificationScreen(),
                    ),
                  );
                },
                trailing: isVerified
                    ? Text(
                        'Verified',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.feedbackSuccess,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              AppGroupedListTile(
                iconPath: AppIcons.discover,
                label: 'Discovery preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const MatchingPreferencesScreen(),
                    ),
                  );
                },
              ),
              AppGroupedListTile(
                iconPath: AppIcons.flash,
                label: 'Boost profile',
                onTap: () => context.pushNamed('subscription-plans'),
                trailing: isBasid
                    ? AppSvgIcon(
                        assetPath: AppIcons.lockOutline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      )
                    : Text(
                        'Get more views',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subscriptionCard(
    BuildContext context, {
    required UserTier tier,
    required SubscriptionStatus? subscription,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (tier == UserTier.basid) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: primary.withValues(alpha: 0.30), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppSvgIcon(assetPath: AppIcons.crown, size: 18, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        'Go Premium',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock unlimited likes, see who liked you, and more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.spacingMD),
            OutlinedButton(
              onPressed: () => context.pushNamed('subscription-plans'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 40),
                side: BorderSide(color: primary),
                foregroundColor: primary,
              ),
              child: Text('Upgrade', style: theme.textTheme.labelSmall),
            ),
          ],
        ),
      );
    }

    final tierLabel = tier == UserTier.golden ? 'Golden' : 'Silder';
    final expiry = subscription?.endDate ?? subscription?.nextBillingDate;
    final expiryText = expiry != null
        ? _formatDate(expiry)
        : '—'; // TODO: expiry from subscription:status cache when missing

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.20), width: 0.5),
      ),
      child: Row(
        children: [
          AppSvgIcon(assetPath: AppIcons.crown, size: 20, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$tierLabel Member',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Active until $expiryText',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.pushNamed('subscription-management'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              'Manage',
              style: theme.textTheme.bodySmall?.copyWith(color: primary),
            ),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ProfileEditPage()),
    );
  }

  int? _age(UserProfile profile) {
    if (profile.birthDate == null) return null;
    try {
      final birth = DateTime.parse(profile.birthDate!);
      final today = DateTime.now();
      var age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  String? _locationLabel(UserProfile profile) {
    final parts = <String>[];
    if (profile.city != null && profile.city!.isNotEmpty) parts.add(profile.city!);
    if (profile.country != null && profile.country!.isNotEmpty) {
      parts.add(profile.country!);
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  List<String> _resolveLabels(
    List<String>? apiTitles,
    List<int>? ids,
    List<ReferenceItem> refs,
  ) {
    if (apiTitles != null && apiTitles.isNotEmpty) return apiTitles;
    return _mapReferenceIds(ids, refs);
  }

  List<String> _mapReferenceIds(List<int>? ids, List<ReferenceItem> refs) {
    if (ids == null || ids.isEmpty) return const [];
    final byId = {for (final item in refs) item.id: item.title};
    return ids
        .map((id) => byId[id])
        .whereType<String>()
        .where((title) => title.isNotEmpty)
        .toList();
  }

  String? _firstLabel(
    List<String>? apiTitles,
    List<int>? ids,
    List<ReferenceItem> refs,
  ) {
    if (apiTitles != null && apiTitles.isNotEmpty) return apiTitles.first;
    final mapped = _mapReferenceIds(ids, refs);
    return mapped.isEmpty ? null : mapped.first;
  }

  String? _labelForId(int? id, List<ReferenceItem> refs) {
    if (id == null || id <= 0) return null;
    for (final item in refs) {
      if (item.id == id) return item.title;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

class _CameraOverlayButton extends StatelessWidget {
  const _CameraOverlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AppSvgIcon(
          assetPath: AppIcons.camera,
          size: 13,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CompletenessArcPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color arcColor;

  _CompletenessArcPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const start = -3.1415926535 / 2;
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, 3.1415926535 * 2, false, track);

    final arc = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, 3.1415926535 * 2 * progress.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(covariant _CompletenessArcPainter old) =>
      old.progress != progress;
}
