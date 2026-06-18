import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/border_radius_constants.dart';
import '../../../../../core/theme/spacing_constants.dart';
import '../../../../../core/utils/app_icons.dart';
import '../../../../../core/widgets/app_page_header.dart';
import '../../../../../shared/models/user_tier.dart';
import '../../../data/models/user_profile.dart';
import '../../../widgets/tier_badge.dart';
import '../../../../reference_data/data/models/reference_item.dart';

/// Full-screen layout for viewing another user's profile (chat, discovery, etc.).
class OtherUserProfileView extends ConsumerStatefulWidget {
  final UserProfile profile;
  final bool showInteractionActions;
  final bool isMatched;
  final VoidCallback? onMessage;
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
  late final PageController _photoController;
  int _photoIndex = 0;

  static const double _horizontalPad = AppPageHeader.horizontalPadding;
  static const double _sheetOverlap = 20;

  @override
  void initState() {
    super.initState();
    _photoController = PageController();
  }

  @override
  void dispose() {
    _photoController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final actionBarHeight =
        widget.showInteractionActions ? 88.0 + bottomInset : 0.0;
    final messageBarHeight =
        !widget.showInteractionActions && widget.onMessage != null
            ? 72.0 + bottomInset
            : 0.0;
    final bottomPad = actionBarHeight > 0
        ? actionBarHeight
        : messageBarHeight > 0
            ? messageBarHeight
            : AppSpacing.spacingXXL;

    return Stack(
      fit: StackFit.expand,
      children: [
        RefreshIndicator(
          onRefresh: widget.onRefresh ?? () async {},
          edgeOffset: MediaQuery.paddingOf(context).top,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _photoHero(context)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -_sheetOverlap),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _horizontalPad,
                        AppSpacing.spacingLG,
                        _horizontalPad,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!widget.showInteractionActions &&
                              widget.onMessage != null)
                            _messageButton(context),
                          if (_hasBio) ...[
                            _aboutSection(context),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (widget.interestLabels.isNotEmpty) ...[
                            _interestsSection(context),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (_hasBasics) ...[
                            _basicsSection(context),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (widget.jobLabels.isNotEmpty) ...[
                            _tagSection(context, 'Work', widget.jobLabels,
                                AppIcons.getIconPath('briefcase')),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (widget.educationLabels.isNotEmpty) ...[
                            _tagSection(context, 'Education',
                                widget.educationLabels,
                                AppIcons.getIconPath('teacher')),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (widget.languageLabels.isNotEmpty) ...[
                            _tagSection(context, 'Languages',
                                widget.languageLabels,
                                AppIcons.getIconPath('global')),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (widget.musicLabels.isNotEmpty) ...[
                            _tagSection(context, 'Music', widget.musicLabels,
                                AppIcons.getIconPath('music')),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (widget.relationGoalLabels.isNotEmpty) ...[
                            _tagSection(context, 'Looking for',
                                widget.relationGoalLabels, AppIcons.heartOutline),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (widget.preferredGenderLabels.isNotEmpty) ...[
                            _tagSection(
                              context,
                              'Interested in',
                              widget.preferredGenderLabels,
                              AppIcons.getIconPath('people'),
                            ),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          if (_hasLifestyle) ...[
                            _lifestyleSection(context),
                            const SizedBox(height: AppSpacing.spacingXL),
                          ],
                          SizedBox(height: bottomPad),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacingXS,
              AppSpacing.spacingSM,
              _horizontalPad,
              0,
            ),
            child: Row(
              children: [
                _circleHeaderButton(
                  context,
                  icon: AppIcons.arrowLeft,
                  onTap: () => Navigator.maybePop(context),
                  tooltip: 'Back',
                ),
                const Spacer(),
                if (widget.onMoreOptions != null)
                  _circleHeaderButton(
                    context,
                    icon: AppIcons.more,
                    onTap: widget.onMoreOptions!,
                    tooltip: 'More options',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool get _hasBio {
    final bio = widget.profile.profileBio?.trim();
    return bio != null && bio.isNotEmpty;
  }

  bool get _hasBasics =>
      widget.locationLabel.isNotEmpty ||
      (widget.genderLabel != null && widget.genderLabel!.isNotEmpty);

  bool get _hasLifestyle =>
      widget.profile.height != null ||
      widget.profile.weight != null ||
      widget.profile.smoke != null ||
      widget.profile.drink != null ||
      widget.profile.gym != null;

  Widget _photoHero(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = width * 1.05;
    final urls = _imageUrls;
    final age = _age;
    final isVerified = widget.profile.isVerified == true;
    final isOnline = widget.profile.isOnline == true;

    if (urls.isEmpty) {
      return SizedBox(
        height: heroHeight,
        width: width,
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: AppSvgIcon(
              assetPath: AppIcons.userOutline,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: heroHeight,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _photoController,
            onPageChanged: (index) => setState(() => _photoIndex = index),
            itemCount: urls.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: urls[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: AppIcons.gallery,
                      size: 40,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 56,
              right: _horizontalPad,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingSM,
                  vertical: AppSpacing.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                ),
                child: Text(
                  '${_photoIndex + 1}/${urls.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            left: _horizontalPad,
            right: _horizontalPad,
            bottom: _sheetOverlap + AppSpacing.spacingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        age != null ? '$_fullName, $age' : _fullName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isVerified)
                      AppSvgIcon(
                        assetPath: AppIcons.getIconPath('verify', style: 'bold'),
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Row(
                  children: [
                    TierBadge(tier: _tier, compact: false),
                    if (isOnline) ...[
                      const SizedBox(width: AppSpacing.spacingSM),
                      _onlinePill(context),
                    ],
                    if (widget.locationLabel.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Row(
                          children: [
                            AppSvgIcon(
                              assetPath: AppIcons.location,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: _sheetOverlap + AppSpacing.spacingSM,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _photoController,
                  count: urls.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 6,
                    dotWidth: 6,
                    expansionFactor: 3,
                    spacing: 4,
                    activeDotColor: theme.colorScheme.primary,
                    dotColor: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _onlinePill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.feedbackSuccess.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: AppColors.feedbackSuccess.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        'Online',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.feedbackSuccess,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _circleHeaderButton(
    BuildContext context, {
    required String icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: AppSvgIcon(assetPath: icon, size: 22, color: Colors.white),
      ),
    );
  }

  Widget _messageButton(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingXL),
      child: FilledButton.icon(
        onPressed: widget.onMessage,
        icon: AppSvgIcon(
          assetPath: AppIcons.message,
          size: 20,
          color: theme.colorScheme.onPrimary,
        ),
        label: Text(widget.isMatched ? 'Send message' : 'Message'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingMD),
        child: child,
      ),
    );
  }

  Widget _aboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'About'),
        const SizedBox(height: AppSpacing.spacingSM),
        _sectionCard(
          context,
          child: Text(
            widget.profile.profileBio!.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.55,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.85),
                ),
          ),
        ),
      ],
    );
  }

  Widget _interestsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Interests'),
        const SizedBox(height: AppSpacing.spacingSM),
        _sectionCard(
          context,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.interestLabels
                .map((label) => _infoPill(context, AppIcons.getIconPath('tag'), label))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _basicsSection(BuildContext context) {
    final pills = <Widget>[];
    if (widget.locationLabel.isNotEmpty) {
      pills.add(_infoPill(context, AppIcons.location, widget.locationLabel));
    }
    if (widget.genderLabel != null && widget.genderLabel!.isNotEmpty) {
      pills.add(_infoPill(context, AppIcons.userOutline, widget.genderLabel!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Basics'),
        const SizedBox(height: AppSpacing.spacingSM),
        _sectionCard(
          context,
          child: Wrap(spacing: 8, runSpacing: 8, children: pills),
        ),
      ],
    );
  }

  Widget _lifestyleSection(BuildContext context) {
    final profile = widget.profile;
    final pills = <Widget>[];
    if (profile.height != null) {
      pills.add(_infoPill(
        context,
        AppIcons.getIconPath('ruler'),
        '${profile.height} cm',
      ));
    }
    if (profile.weight != null) {
      pills.add(_infoPill(
        context,
        AppIcons.getIconPath('weight'),
        '${profile.weight} kg',
      ));
    }
    if (profile.smoke != null) {
      pills.add(_infoPill(
        context,
        AppIcons.getIconPath('cloud'),
        'Smoking: ${profile.smoke! ? 'Yes' : 'No'}',
      ));
    }
    if (profile.drink != null) {
      pills.add(_infoPill(
        context,
        AppIcons.getIconPath('cup'),
        'Drinking: ${profile.drink! ? 'Yes' : 'No'}',
      ));
    }
    if (profile.gym != null) {
      pills.add(_infoPill(
        context,
        AppIcons.getIconPath('activity'),
        'Gym: ${profile.gym! ? 'Yes' : 'No'}',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Lifestyle'),
        const SizedBox(height: AppSpacing.spacingSM),
        _sectionCard(
          context,
          child: Wrap(spacing: 8, runSpacing: 8, children: pills),
        ),
      ],
    );
  }

  Widget _tagSection(
    BuildContext context,
    String title,
    List<String> labels,
    String iconPath,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, title),
        const SizedBox(height: AppSpacing.spacingSM),
        _sectionCard(
          context,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                labels.map((label) => _infoPill(context, iconPath, label)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _infoPill(BuildContext context, String iconPath, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            assetPath: iconPath,
            size: 15,
            color: theme.colorScheme.primary,
          ),
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
