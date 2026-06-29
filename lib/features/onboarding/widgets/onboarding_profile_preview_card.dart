import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/profile_age_badge.dart';
import '../../../core/widgets/profile_image_widget.dart';

/// Discovery-style mini profile preview shown after onboarding completion.
class OnboardingProfilePreviewCard extends ConsumerStatefulWidget {
  final String displayName;
  final int? age;
  final String? location;
  final String? bio;
  final String? relationshipGoal;
  final int? heightCm;
  final List<String> photoSources;
  final List<String> interests;

  const OnboardingProfilePreviewCard({
    super.key,
    required this.displayName,
    this.age,
    this.location,
    this.bio,
    this.relationshipGoal,
    this.heightCm,
    this.photoSources = const [],
    this.interests = const [],
  });

  @override
  ConsumerState<OnboardingProfilePreviewCard> createState() =>
      _OnboardingProfilePreviewCardState();
}

class _OnboardingProfilePreviewCardState
    extends ConsumerState<OnboardingProfilePreviewCard> {
  late final PageController _pageController;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _photos =>
      widget.photoSources.where((s) => s.trim().isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight;
    final borderColor =
        isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.radiusXL),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.backgroundDark.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_photos.isEmpty)
                  _PhotoPlaceholder(isDark: isDark)
                else
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _photos.length,
                    onPageChanged: (index) => setState(() => _photoIndex = index),
                    itemBuilder: (context, index) =>
                        _CelebrationPhoto(source: _photos[index]),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0.45, 0.72, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.spacingLG,
                  right: AppSpacing.spacingLG,
                  bottom: AppSpacing.spacingLG,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.location != null &&
                                widget.location!.isNotEmpty) ...[
                              SizedBox(height: AppSpacing.spacingXS),
                              Row(
                                children: [
                                  AppSvgIcon(
                                    assetPath: AppIcons.location,
                                    size: 14,
                                    color: AppColors.textPrimaryDark
                                        .withValues(alpha: 0.85),
                                  ),
                                  SizedBox(width: AppSpacing.spacingXS),
                                  Expanded(
                                    child: Text(
                                      widget.location!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textPrimaryDark
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.age != null)
                  Positioned(
                    top: AppSpacing.spacingMD,
                    right: AppSpacing.spacingMD,
                    child: ProfileAgeBadge(
                      age: widget.age!,
                      style: ProfileAgeBadgeStyle.photoOverlay,
                    ),
                  ),
                if (_photos.length > 1)
                  Positioned(
                    top: AppSpacing.spacingMD,
                    left: AppSpacing.spacingMD,
                    right: AppSpacing.spacingMD,
                    child: Row(
                      children: List.generate(_photos.length, (index) {
                        final active = index == _photoIndex;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: EdgeInsets.only(
                              right: index == _photos.length - 1
                                  ? 0
                                  : AppSpacing.spacingXS,
                            ),
                            height: 3,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryDark
                                      .withValues(alpha: 0.35),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.radiusRound),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
          if (_photos.length > 1)
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.all(AppSpacing.spacingMD),
                itemCount: _photos.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: AppSpacing.spacingSM),
                itemBuilder: (context, index) {
                  final selected = index == _photoIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusSM),
                        border: Border.all(
                          color: selected
                              ? AppColors.accentRose
                              : borderColor.withValues(alpha: 0.5),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _CelebrationPhoto(source: _photos[index]),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.spacingLG,
              _photos.length > 1 ? 0 : AppSpacing.spacingMD,
              AppSpacing.spacingLG,
              AppSpacing.spacingLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.bio != null && widget.bio!.trim().isNotEmpty) ...[
                  Text(
                    widget.bio!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                ],
                if (widget.relationshipGoal != null ||
                    widget.heightCm != null)
                  Wrap(
                    spacing: AppSpacing.spacingSM,
                    runSpacing: AppSpacing.spacingSM,
                    children: [
                      if (widget.relationshipGoal != null &&
                          widget.relationshipGoal!.isNotEmpty)
                        _InfoChip(
                          iconPath: AppIcons.heart,
                          label: widget.relationshipGoal!,
                          isDark: isDark,
                        ),
                      if (widget.heightCm != null)
                        _InfoChip(
                          iconPath: AppIcons.profileCircle,
                          label: '${widget.heightCm} cm',
                          isDark: isDark,
                        ),
                    ],
                  ),
                if ((widget.relationshipGoal != null &&
                        widget.relationshipGoal!.isNotEmpty) ||
                    widget.heightCm != null)
                  SizedBox(height: AppSpacing.spacingMD),
                if (widget.interests.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.spacingSM,
                    runSpacing: AppSpacing.spacingSM,
                    children: widget.interests.take(6).map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingMD,
                          vertical: AppSpacing.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tintRoseLight,
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusRound),
                          border: Border.all(
                            color: AppColors.accentRose.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.accentRose,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationPhoto extends ConsumerWidget {
  final String source;

  const _CelebrationPhoto({required this.source});

  bool get _isNetwork => source.startsWith('http');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isNetwork) {
      return ProfileImageWidget(
        imageUrl: source,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final file = File(source);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PhotoPlaceholder(isDark: true),
      );
    }

    return const _PhotoPlaceholder(isDark: true);
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final bool isDark;

  const _PhotoPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      alignment: Alignment.center,
      child: AppSvgIcon(
        assetPath: AppIcons.user,
        size: 56,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.iconPath,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingMD,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color:
              isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            assetPath: iconPath,
            size: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          SizedBox(width: AppSpacing.spacingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
          ),
        ],
      ),
    );
  }
}
