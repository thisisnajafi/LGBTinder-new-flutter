import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/spacing_constants.dart';
import '../../../../../shared/models/user_tier.dart';
import '../../../data/models/user_profile.dart';
import '../../../../reference_data/data/models/reference_item.dart';
import '../../../../reference_data/providers/reference_data_providers.dart';
import '../../../providers/profile_page_cache_provider.dart';
import '../own_profile/profile_details_sections.dart';
import '../own_profile/profile_hero_section.dart';
import '../own_profile/profile_photo_utils.dart';
import 'other_user_profile_sections.dart';

class OtherUserProfileView extends ConsumerStatefulWidget {
  final UserProfile profile;
  final bool showInteractionActions;
  final bool isMatched;
  final VoidCallback? onMessage;
  final VoidCallback? onLike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onShare;
  final VoidCallback? onMoreOptions;
  final Future<void> Function()? onRefresh;
  final void Function(int index)? onPhotoTap;
  final List<String> interestLabels;
  final List<String> jobLabels;
  final List<String> educationLabels;
  final List<String> languageLabels;
  final List<String> musicLabels;
  final List<String> relationGoalLabels;
  final List<String> preferredGenderLabels;
  final String? genderLabel;
  final String locationLabel;

  const OtherUserProfileView({
    super.key,
    required this.profile,
    required this.locationLabel,
    this.showInteractionActions = false,
    this.isMatched = false,
    this.onMessage,
    this.onLike,
    this.onSuperlike,
    this.onShare,
    this.onMoreOptions,
    this.onRefresh,
    this.onPhotoTap,
    this.interestLabels = const [],
    this.jobLabels = const [],
    this.educationLabels = const [],
    this.languageLabels = const [],
    this.musicLabels = const [],
    this.relationGoalLabels = const [],
    this.preferredGenderLabels = const [],
    this.genderLabel,
  });

  @override
  ConsumerState<OtherUserProfileView> createState() =>
      _OtherUserProfileViewState();
}

class _OtherUserProfileViewState extends ConsumerState<OtherUserProfileView> {
  static const double _sectionGap = AppSpacing.spacingXL;

  String get _fullName {
    final profile = widget.profile;
    return '${profile.firstName} ${profile.lastName}'.trim();
  }

  int? get _age {
    final raw = widget.profile.birthDate;
    if (raw == null || raw.isEmpty) return null;
    try {
      final birth = DateTime.parse(raw);
      final now = DateTime.now();
      var age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  UserTier get _tier => tierFromUserProfile(widget.profile);

  String get _locationDisplay {
    final distance = widget.profile.additionalData?['distance'];
    final base = widget.locationLabel;
    if (distance != null) {
      final km =
          distance is num ? distance.toDouble() : double.tryParse('$distance');
      if (km != null) {
        final distanceText = '${km.toStringAsFixed(1)} km away';
        if (base.isNotEmpty) return '$base · $distanceText';
        return distanceText;
      }
    }
    return base;
  }

  int? get _apiMatchPercent {
    final profile = widget.profile;
    if (profile.matchPercentage != null && profile.matchPercentage! > 0) {
      return profile.matchPercentage;
    }
    final raw = profile.additionalData?['compatibility_score'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final viewerProfile =
        ref.watch(profilePageCacheProvider).valueOrNull?.profile;
    final interestsRef = ref.watch(interestsProvider).valueOrNull ?? const [];
    final relationGoalsRef =
        ref.watch(relationshipGoalsProvider).valueOrNull ?? const [];

    final viewerInterestLabels = viewerProfile != null
        ? profileLabelsFromRefs(
            apiTitles: viewerProfile.interestTitles,
            ids: viewerProfile.interests,
            refs: interestsRef,
          )
        : const <String>[];

    final viewerGoalLabels = viewerProfile != null
        ? profileLabelsFromRefs(
            ids: viewerProfile.relationGoals,
            refs: relationGoalsRef,
          )
        : const <String>[];

    final compatibility = computeProfileCompatibility(
      theirInterests: widget.interestLabels,
      viewerInterests: viewerInterestLabels,
      theirGoals: widget.relationGoalLabels,
      viewerGoals: viewerGoalLabels,
      theirSmoke: widget.profile.smoke,
      viewerSmoke: viewerProfile?.smoke,
      theirDrink: widget.profile.drink,
      viewerDrink: viewerProfile?.drink,
      theirGym: widget.profile.gym,
      viewerGym: viewerProfile?.gym,
      apiMatchPercent: _apiMatchPercent,
    );

    final conversationStarters = buildConversationStarters(
      city: widget.profile.city,
      interests: widget.interestLabels,
      job: widget.jobLabels.isNotEmpty ? widget.jobLabels.first : null,
    );

    final detailChips = buildProfileDetailChips(
      job: widget.jobLabels.isNotEmpty ? widget.jobLabels.first : null,
      education:
          widget.educationLabels.isNotEmpty ? widget.educationLabels.first : null,
      height: widget.profile.height,
      gender: widget.genderLabel,
      relationGoals: widget.relationGoalLabels,
      languages: widget.languageLabels,
      smoke: widget.profile.smoke,
      drink: widget.profile.drink,
      gym: widget.profile.gym,
    );

    final photos = widget.profile.images ?? [];
    final primaryImage = primaryProfileImage(photos);
    final avatarUrl = primaryImage?.imageUrl;
    final photoUrls = orderedProfilePhotoUrls(photos);
    final galleryUrls = galleryProfileImages(photos).map((p) => p.imageUrl).toList();

    final bio = widget.profile.profileBio?.trim();
    final hasAbout = (bio != null && bio.isNotEmpty) ||
        conversationStarters.isNotEmpty;

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeroSection(
                  fullName: _fullName,
                  avatarUrl: avatarUrl,
                  photoUrls: photoUrls,
                  age: _age,
                  isVerified: widget.profile.isVerified == true,
                  tier: _tier,
                  locationLabel: _locationDisplay,
                  isOnline: widget.profile.isOnline == true,
                  viewsCount: widget.profile.viewsCount ?? 0,
                  superlikesRemaining: null,
                  onEditProfile: () {},
                  onEditPhoto: () {},
                  onViewProfile: () {},
                  viewerMode: true,
                  onBack: () => Navigator.maybePop(context),
                  onMessage: widget.onMessage,
                  onLike: widget.showInteractionActions ? widget.onLike : null,
                  onMore: widget.onMoreOptions,
                  matchPercent: compatibility.matchPercent,
                  onPhotoTap: widget.onPhotoTap,
                ),
                const SizedBox(height: _sectionGap),
                PremiumCompatibilitySection(data: compatibility),
                if (photoUrls.isNotEmpty) ...[
                  const SizedBox(height: _sectionGap),
                  PremiumPhotosSection(
                    imageUrls: galleryUrls.isNotEmpty ? galleryUrls : photoUrls,
                    totalCount: photoUrls.length,
                    onEdit: () {},
                    onAdd: () {},
                    canAddMore: false,
                    readOnly: true,
                    onPhotoTap: widget.onPhotoTap ?? (_) {},
                  ),
                ],
                if (hasAbout) ...[
                  const SizedBox(height: _sectionGap),
                  PremiumPersonalitySection(
                    bio: bio,
                    conversationStarters: conversationStarters,
                    sectionTitle: 'About',
                    sectionSubtitle: 'Get to know them',
                    quoteBio: false,
                    readOnly: true,
                  ),
                ],
                if (detailChips.isNotEmpty) ...[
                  const SizedBox(height: _sectionGap),
                  PremiumDetailsGridSection(
                    chips: detailChips,
                    sectionTitle: 'About them',
                    sectionSubtitle: 'Identity, lifestyle, and preferences',
                  ),
                ],
                if (widget.interestLabels.isNotEmpty) ...[
                  const SizedBox(height: _sectionGap),
                  PremiumSharedInterestsSection(
                    allLabels: widget.interestLabels,
                    sharedLabels: compatibility.sharedInterests.toSet(),
                  ),
                ],
                SizedBox(height: AppSpacing.spacingXXL + bottomInset),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Resolve another user's plan tier from profile payload (not the viewer's tier).
UserTier tierFromUserProfile(UserProfile profile) {
  final data = profile.additionalData;
  final planName = data?['plan_name']?.toString() ??
      data?['plan_title']?.toString() ??
      data?['subscription_plan']?.toString();
  final rawPlanId = data?['plan_id'];
  final planId = rawPlanId is int
      ? rawPlanId
      : int.tryParse(rawPlanId?.toString() ?? '');

  if (planName != null || planId != null) {
    return userTierFromPlan(planId: planId, planName: planName);
  }
  if (profile.isPremium == true) return UserTier.silder;
  return UserTier.basid;
}

/// Shared label resolver for profile reference IDs.
List<String> profileLabelsFromRefs({
  List<String>? apiTitles,
  List<int>? ids,
  List<ReferenceItem> refs = const [],
}) {
  if (apiTitles != null && apiTitles.isNotEmpty) {
    return apiTitles.where((t) => t.trim().isNotEmpty).toList();
  }
  if (ids == null || ids.isEmpty) return const [];
  final byId = {for (final item in refs) item.id: item.title};
  return ids
      .map((id) => byId[id])
      .whereType<String>()
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();
}

String? profileGenderLabel(UserProfile profile, List<ReferenceItem> gendersRef) {
  if (profile.gender != null && profile.gender!.trim().isNotEmpty) {
    return profile.gender;
  }
  if (profile.genderId == null) return null;
  for (final item in gendersRef) {
    if (item.id == profile.genderId) return item.title;
  }
  return null;
}

String profileLocationLabel(UserProfile profile) {
  final parts = <String>[];
  if (profile.city != null && profile.city!.trim().isNotEmpty) {
    parts.add(profile.city!.trim());
  }
  if (profile.country != null && profile.country!.trim().isNotEmpty) {
    parts.add(profile.country!.trim());
  }
  return parts.join(', ');
}
