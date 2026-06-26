import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cache/session_cache_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/spacing_constants.dart';
import '../../../../../core/utils/app_icons.dart';
import '../../../../payments/data/models/plan_limits.dart';
import '../../../../payments/data/models/subscription_plan.dart';
import '../../../../payments/providers/payment_providers.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/profile_page_cache_provider.dart';
import '../../../../reference_data/data/models/reference_item.dart';
import '../../../../reference_data/providers/reference_data_providers.dart';
import '../../../../settings/presentation/screens/matching_preferences_screen.dart';
import '../../../../../routes/app_router.dart';
import '../../../../../screens/active_sessions_screen.dart';
import '../../../../../screens/privacy_settings_screen.dart';
import '../../../../../screens/profile/profile_verification_screen.dart';
import '../../../../../shared/models/user_tier.dart';
import '../../../../../shared/providers/user_tier_provider.dart';
import 'profile_details_sections.dart';
import 'profile_hero_section.dart';
import 'profile_premium_shell.dart';
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

    final UserTier fallbackTier = ref.watch(userTierProvider);
    final superlikes = ref.watch(superlikesRemainingProvider);

    final cacheData = ref.watch(profilePageCacheProvider).valueOrNull;
    final sessionCache = ref.watch(sessionDataCacheServiceProvider);
    final cachedSub = sessionCache.getSubscriptionStatusSync();
    final subAsync = ref.watch(subscriptionStatusProvider);
    final subscription =
        cacheData?.subscription ?? cachedSub ?? subAsync.valueOrNull;
    final tier = _resolveTier(
      subscription: subscription,
      planLimits: cacheData?.planLimits,
      fallback: fallbackTier,
    );

    final interestsRef = ref.watch(interestsProvider).valueOrNull ?? const [];
    final jobsRef = ref.watch(jobsProvider).valueOrNull ?? const [];
    final educationsRef = ref.watch(educationLevelsProvider).valueOrNull ?? const [];
    final gendersRef = ref.watch(gendersProvider).valueOrNull ?? const [];
    final languagesRef = ref.watch(languagesProvider).valueOrNull ?? const [];
    final relationGoalsRef =
        ref.watch(relationshipGoalsProvider).valueOrNull ?? const [];

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
    final relationGoalLabels = _mapReferenceIds(profile.relationGoals, relationGoalsRef);
    final languageLabels = _mapReferenceIds(profile.languages, languagesRef);

    final photos = profile.images ?? [];
    final photoUrls = photos.map((p) => p.imageUrl).toList();
    final detailChips = buildProfileDetailChips(
      job: jobLabel,
      education: educationLabel,
      height: profile.height,
      gender: genderLabel,
      relationGoals: relationGoalLabels,
      languages: languageLabels,
      smoke: profile.smoke,
      drink: profile.drink,
      gym: profile.gym,
    );
    final hubActions = _buildHubActions(
      context,
      isVerified: isVerified,
      tier: tier,
    );

    return CustomScrollView(      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeroSection(
                fullName: fullName,
                avatarUrl: avatarUrl,
                age: age,
                isVerified: isVerified,
                tier: tier,
                locationLabel: locationLabel,
                isOnline: profile.isOnline ?? false,
                viewsCount: profile.viewsCount ?? 0,
                superlikesRemaining: superlikes,
                onEditProfile: () => _openEdit(context),
                onEditPhoto: onEditPhotos,
                onViewProfile: onViewProfile,
              ),
              const SizedBox(height: _sectionGap),
              PremiumPhotosSection(                imageUrls: photoUrls,
                totalCount: photos.length,
                onEdit: onEditPhotos,
                onAdd: onAddPhoto,
                onPhotoTap: onPhotoTap,
              ),
              const SizedBox(height: _sectionGap),
              PremiumPersonalitySection(
                bio: profile.profileBio,
                conversationStarters: const [],
                onEdit: () => _openEdit(context),
              ),              const SizedBox(height: _sectionGap),
              PremiumDetailsGridSection(
                chips: detailChips,
                onEdit: () => _openEdit(context),
              ),
              const SizedBox(height: _sectionGap),
              PremiumInterestsSection(
                labels: interestLabels,
                onEdit: () => _openEdit(context),
              ),
              const SizedBox(height: _sectionGap),
              PremiumAccountHubSection(actions: hubActions),
              const SizedBox(height: _sectionGap),
              PremiumMembershipSection(
                tier: tier,
                subscription: subscription,
                onUpgrade: () => context.pushNamed('subscription-plans'),
                onManage: () => context.pushNamed('subscription-management'),
              ),
              const SizedBox(height: AppSpacing.spacingXXL),            ],
          ),
        ),
      ],
    );
  }

  UserTier _resolveTier({
    required SubscriptionStatus? subscription,
    required PlanLimits? planLimits,
    required UserTier fallback,
  }) {
    if (subscription != null) {
      if (subscription.tier != null && subscription.tier!.isNotEmpty) {
        return UserTier.values.firstWhere(
          (t) => t.key == subscription.tier,
          orElse: () => userTierFromPlan(
            planId: subscription.planId,
            planName: subscription.planName,
          ),
        );
      }
      return userTierFromPlan(
        planId: subscription.planId,
        planName: subscription.planName,
      );
    }
    if (planLimits != null) {
      return userTierFromPlan(
        planId: planLimits.planInfo.planId,
        planName: planLimits.planInfo.planName,
      );
    }
    return fallback;
  }

  List<ProfileHubActionData> _buildHubActions(
    BuildContext context, {
    required bool isVerified,
    required UserTier tier,
  }) {
    final isBasid = tier == UserTier.basid;

    void pushScreen(Widget screen) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => screen),
      );
    }

    return [
      ProfileHubActionData(
        iconPath: AppIcons.verify,
        title: 'Verification',
        subtitle: isVerified ? 'Identity confirmed' : 'Build trust faster',
        statusLabel: isVerified ? 'Verified' : 'Pending',
        statusColor:
            isVerified ? AppColors.feedbackSuccess : AppColors.feedbackWarning,
        onTap: () => pushScreen(const ProfileVerificationScreen()),
      ),
      ProfileHubActionData(
        iconPath: AppIcons.discover,
        title: 'Discovery',
        subtitle: 'Who you want to meet',
        onTap: () => pushScreen(const MatchingPreferencesScreen()),
      ),
      ProfileHubActionData(
        iconPath: AppIcons.shield,
        title: 'Privacy',
        subtitle: 'Visibility & data controls',
        onTap: () => pushScreen(const PrivacySettingsScreen()),
      ),
      ProfileHubActionData(
        iconPath: AppIcons.lockOutline,
        title: 'Security',
        subtitle: 'Sessions & sign-in',
        onTap: () => pushScreen(const ActiveSessionsScreen()),
      ),
      ProfileHubActionData(
        iconPath: AppIcons.flash,
        title: 'Boost',
        subtitle: isBasid ? 'Premium feature' : 'Get more views',
        locked: isBasid,
        onTap: () => context.pushNamed('subscription-plans'),
      ),
    ];
  }

  void _openEdit(BuildContext context) {    context.push(AppRoutes.profileEdit);
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
}
