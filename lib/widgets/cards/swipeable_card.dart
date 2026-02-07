// Widget: SwipeableCard
// Swipeable card component
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../images/optimized_image.dart';
import '../badges/verification_badge.dart';
import '../badges/premium_badge.dart';
import '../../core/utils/app_icons.dart';

/// Swipeable card widget
/// Profile card for discovery screen with swipe gestures
/// Data structure based on API: /api/matching/discover
class SwipeableCard extends ConsumerStatefulWidget {
  final int userId;
  final String name;
  final int? age;
  final String? location;
  final String? avatarUrl;
  final List<String>? imageUrls;
  final String? bio;
  final bool isVerified;
  final bool isPremium;
  final double? distance;
  final Function()? onLike;
  final Function()? onDislike;
  final Function()? onSuperlike;
  final Function()? onTap;

  const SwipeableCard({
    Key? key,
    required this.userId,
    required this.name,
    this.age,
    this.location,
    this.avatarUrl,
    this.imageUrls,
    this.bio,
    this.isVerified = false,
    this.isPremium = false,
    this.distance,
    this.onLike,
    this.onDislike,
    this.onSuperlike,
    this.onTap,
  }) : super(key: key);

  @override
  ConsumerState<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends ConsumerState<SwipeableCard> {
  int _currentImageIndex = 0;

  Widget _buildBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final images = widget.imageUrls ?? (widget.avatarUrl != null ? [widget.avatarUrl!] : []);
    final currentImage = images.isNotEmpty ? images[_currentImageIndex] : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.only(
          left: AppSpacing.spacingLG,
          right: AppSpacing.spacingLG,
          top: AppSpacing.spacingMD,
          bottom: AppSpacing.spacingMD,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          child: Stack(
            children: [
              // Image
              if (currentImage != null)
                OptimizedImage(
                  imageUrl: currentImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 100,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Top left badges
              Positioned(
                top: AppSpacing.spacingLG,
                left: AppSpacing.spacingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sample interest/profession badges (rounded pills)
                    Wrap(
                      spacing: AppSpacing.spacingXS,
                      runSpacing: AppSpacing.spacingXS,
                      children: [
                        // Sample badges - in real app these would come from profile data
                        _buildBadge('Aries'),
                        _buildBadge('Designer'),
                        _buildBadge('Blogger'),
                      ],
                    ),
                    // Verification/Premium badges below
                    if (widget.isVerified || widget.isPremium)
                      Padding(
                        padding: EdgeInsets.only(top: AppSpacing.spacingSM),
                        child: Row(
                          children: [
                            if (widget.isVerified)
                              VerificationBadge(isVerified: widget.isVerified, size: 20),
                            if (widget.isVerified && widget.isPremium)
                              SizedBox(width: AppSpacing.spacingXS),
                            if (widget.isPremium)
                              PremiumBadge(isPremium: widget.isPremium, fontSize: 8),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Top right: Three-dot menu and image indicators
              Positioned(
                top: AppSpacing.spacingLG,
                right: AppSpacing.spacingLG,
                child: Row(
                  children: [
                    // Three-dot menu
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: AppSvgIcon(
                          assetPath: AppIcons.more, // ✅ Verified: AppIcons.more exists
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Show menu options (report, block, etc.) - implementation needed
                          // This would show a popup menu with report/block options
                        },
                      ),
                    ),
                    if (images.length > 1) ...[
                      SizedBox(width: AppSpacing.spacingSM),
                      // Image indicators
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingMD,
                          vertical: AppSpacing.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style: AppTypography.caption.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // User info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator: Green dot + "Active" text
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.onlineGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: AppSpacing.spacingXS),
                          Text(
                            'Active',
                            style: AppTypography.caption.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              style: AppTypography.h1.copyWith(color: Colors.white),
                            ),
                          ),
                          if (widget.age != null)
                            Text(
                              '${widget.age}',
                              style: AppTypography.h2.copyWith(color: Colors.white),
                            ),
                        ],
                      ),
                      if (widget.location != null || widget.distance != null) ...[
                        SizedBox(height: AppSpacing.spacingXS),
                        Row(
                          children: [
                            if (widget.location != null) ...[
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.white70,
                              ),
                              SizedBox(width: AppSpacing.spacingXS),
                              Text(
                                widget.location!,
                                style: AppTypography.body.copyWith(color: Colors.white70),
                              ),
                            ],
                            if (widget.location != null && widget.distance != null)
                              Text(
                                ' • ',
                                style: AppTypography.body.copyWith(color: Colors.white70),
                              ),
                            if (widget.distance != null)
                              Text(
                                '${widget.distance!.toStringAsFixed(1)} km away',
                                style: AppTypography.body.copyWith(color: Colors.white70),
                              ),
                          ],
                        ),
                      ],
                      if (widget.bio != null && widget.bio!.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.spacingMD),
                        Text(
                          widget.bio!,
                          style: AppTypography.body.copyWith(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Image pagination dots
              if (images.length > 1)
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
