import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/profile_image_widget.dart';
import '../../../../widgets/ui/distance_tag.dart';
import '../../data/models/discovery_profile.dart';

/// Profile card widget for discovery
/// Displays a user profile in card format with image, info, and actions
class ProfileCard extends ConsumerWidget {
  final DiscoveryProfile profile;
  final bool isInteractive;
  final bool isPreview;
  final VoidCallback? onTap;

  const ProfileCard({
    Key? key,
    required this.profile,
    this.isInteractive = false,
    this.isPreview = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isInteractive ? onTap : null,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image
              _buildProfileImage(),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.5, 0.7, 1.0],
                  ),
                ),
              ),

              // Content overlay
              _buildContentOverlay(context, theme),

              // Badges and indicators
              _buildBadges(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final imageUrl = profile.primaryImageUrl ??
                     (profile.imageUrls?.isNotEmpty == true ? profile.imageUrls!.first : null);

    return ProfileImageWidget(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildContentOverlay(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Name and age
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.firstName}${profile.lastName != null ? ' ${profile.lastName}' : ''}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.age != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${profile.age}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Location and distance
          if (profile.city != null || profile.distance != null) ...[
            Row(
              children: [
                if (profile.city != null) ...[
                  AppSvgIcon(
                    assetPath: AppIcons.location,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      profile.city!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (profile.distance != null) ...[
                  if (profile.city != null) const SizedBox(width: 8),
                  DistanceTag(
                    distance: profile.distance!,
                    variant: DistanceTagVariant.onDark,
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Bio preview
          if (profile.profileBio != null && profile.profileBio!.isNotEmpty) ...[
            Text(
              profile.profileBio!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Compatibility score (if available)
          if (profile.compatibilityScore != null) ...[
            const SizedBox(height: 8),
            _buildCompatibilityIndicator(context),
          ],
        ],
      ),
    );
  }

  Widget _buildBadges(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Verification badge
          if (profile.isVerified == true) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.feedbackSuccess,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Superlike indicator
          if (profile.isSuperliked == true) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompatibilityIndicator(BuildContext context) {
    final score = profile.compatibilityScore!;
    final percentage = score.clamp(0, 100);

    return Row(
      children: [
        AppSvgIcon(
          assetPath: AppIcons.heart,
          size: 16,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 80
                  ? AppColors.feedbackSuccess
                  : percentage >= 60
                      ? AppColors.feedbackWarning
                      : AppColors.feedbackError,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percentage%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
