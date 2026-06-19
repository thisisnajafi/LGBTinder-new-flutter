import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/spacing_constants.dart';
import '../../../../../shared/models/user_tier.dart';
import '../../../data/models/user_profile.dart';
import '../../../../reference_data/data/models/reference_item.dart';
import '../../../../reference_data/providers/reference_data_providers.dart';
import '../../../providers/profile_page_cache_provider.dart';
import '../own_profile/profile_details_sections.dart';
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
  int _photoIndex = 0;
  Timer? _photoTimer;
  final ScrollController _scrollController = ScrollController();

  static const Duration _photoInterval = Duration(seconds: 5);
  static const double _sectionGap = AppSpacing.spacingXL;

  @override
  void initState() {
    super.initState();
    _startPhotoTimer();
  }

  @override
  void didUpdateWidget(covariant OtherUserProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id ||
        oldWidget.profile.images?.length != widget.profile.images?.length) {
      _photoIndex = 0;
      _startPhotoTimer();
    }
  }

  @override
  void dispose() {
    _photoTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _imageUrls {
    final images = widget.profile.images;
    if (images == null || images.isEmpty) return const [];
    return images.map((img) => img.imageUrl).toList();
  }

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

  bool get _showActionBar =>
      widget.onMessage != null ||
      widget.onMoreOptions != null ||
      widget.onLike != null ||
      widget.onSuperlike != null ||
      widget.onShare != null ||
      widget.showInteractionActions;

  int? get _apiMatchPercent {
    final profile = widget.profile;
    if (profile.matchPercentage != null && profile.matchPercentage! > 0) {
      return profile.matchPercentage;
    }
    final raw = profile.additionalData?['compatibility_score'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  void _startPhotoTimer() {
    _photoTimer?.cancel();
    if (_imageUrls.length <= 1) return;
    _photoTimer = Timer.periodic(_photoInterval, (_) {
      if (!mounted) return;
      _advancePhoto();
    });
  }

  void _advancePhoto() {
    final urls = _imageUrls;
    if (urls.length <= 1) return;
    setState(() {
      _photoIndex = (_photoIndex + 1) % urls.length;
    });
  }

  void _onHeroPhotoTap() {
    _photoTimer?.cancel();
    _advancePhoto();
    _startPhotoTimer();
  }

  void _onGalleryPhotoTap(int index) {
    setState(() => _photoIndex = index);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    _startPhotoTimer();
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

    final detailGroups = buildCategorizedDetailGroups(
      gender: widget.genderLabel,
      height: widget.profile.height,
      smoke: widget.profile.smoke,
      drink: widget.profile.drink,
      gym: widget.profile.gym,
      jobs: widget.jobLabels,
      educations: widget.educationLabels,
      relationGoals: widget.relationGoalLabels,
      preferredGenders: widget.preferredGenderLabels,
      languages: widget.languageLabels,
      musicGenres: widget.musicLabels,
    );

    final bio = widget.profile.profileBio?.trim();
    final hasAbout = (bio != null && bio.isNotEmpty) ||
        conversationStarters.isNotEmpty;

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: OtherUserProfileHero(
              imageUrls: _imageUrls,
              photoIndex: _photoIndex,
              fullName: _fullName,
              age: _age,
              isVerified: widget.profile.isVerified == true,
              isOnline: widget.profile.isOnline == true,
              tier: _tier,
              locationLabel: _locationDisplay,
              matchPercent: compatibility.matchPercent,
              sharedInterestCount: compatibility.sharedInterests.length,
              recentlyActiveLabel: formatRecentlyActive(widget.profile),
              onBack: () => Navigator.maybePop(context),
              onPhotoTap: _imageUrls.length > 1 ? _onHeroPhotoTap : null,
            ),
          ),
          if (_showActionBar)
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProfileActionBarHeader(
                child: OtherUserProfileActionBar(
                  showDiscoveryActions: widget.showInteractionActions,
                  isMatched: widget.isMatched,
                  onMessage: widget.onMessage,
                  onLike: widget.onLike,
                  onSuperlike: widget.onSuperlike,
                  onShare: widget.onShare,
                  onMore: widget.onMoreOptions,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: PremiumCompatibilitySection(data: compatibility),
          ),
          if (hasAbout) ...[
            SliverToBoxAdapter(child: SizedBox(height: _sectionGap)),
            SliverToBoxAdapter(
              child: PremiumPersonalitySection(
                bio: bio,
                conversationStarters: conversationStarters,
                sectionTitle: 'About',
                sectionSubtitle: 'Get to know them',
                quoteBio: false,
                readOnly: true,
              ),
            ),
          ],
          if (widget.interestLabels.isNotEmpty) ...[
            SliverToBoxAdapter(child: SizedBox(height: _sectionGap)),
            SliverToBoxAdapter(
              child: PremiumSharedInterestsSection(
                allLabels: widget.interestLabels,
                sharedLabels: compatibility.sharedInterests.toSet(),
              ),
            ),
          ],
          if (detailGroups.isNotEmpty) ...[
            SliverToBoxAdapter(child: SizedBox(height: _sectionGap)),
            SliverToBoxAdapter(
              child: PremiumCategorizedDetailsSection(groups: detailGroups),
            ),
          ],
          if (_imageUrls.length > 1) ...[
            SliverToBoxAdapter(child: SizedBox(height: _sectionGap)),
            SliverToBoxAdapter(
              child: PremiumViewerPhotosSection(
                imageUrls: _imageUrls,
                onPhotoTap: _onGalleryPhotoTap,
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.spacingXXL + bottomInset),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionBarHeader extends SliverPersistentHeaderDelegate {
  _ProfileActionBarHeader({required this.child});

  final Widget child;

  static const double _height = 70;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).scaffoldBackgroundColor,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileActionBarHeader old) =>
      old.child != child;
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
