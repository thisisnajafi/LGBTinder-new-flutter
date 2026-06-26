import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/widgets/premium/premium_page.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/profile_image_widget.dart';
import '../../../features/profile/providers/profile_page_cache_provider.dart';
import '../../../widgets/loading/skeleton_loader.dart';

class DiscoverGreetingWidget extends ConsumerWidget {
  const DiscoverGreetingWidget({super.key});

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    if (hour >= 18 && hour < 22) return 'Good evening';
    return 'Good night';
  }

  String? _displayFirstName(String? raw) {
    final name = raw?.trim();
    if (name == null || name.isEmpty || name == 'User') return null;
    return name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileState = ref.watch(profilePageCacheProvider);
    final greeting = _timeBasedGreeting();
    final profile = profileState.valueOrNull?.profile;
    final firstName = _displayFirstName(profile?.firstName);
    final avatarUrl = profile?.images?.isNotEmpty == true
        ? profile!.images!.first.imageUrl
        : null;
    final isOnline = profile?.isOnline ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PremiumPageHeader.horizontalPadding,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacingXS),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark.withValues(alpha: 0.92)
              : AppColors.cardBackgroundLight.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.radiusXL),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'View my profile',
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      AppHaptics.light();
                      context.goNamed('profile');
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brandGradient,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surface,
                            ),
                            child: ClipOval(
                              child: ProfileImageWidget(
                                imageUrl: avatarUrl,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.onlineGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingXS),
                  if (firstName == null)
                    const SkeletonLoader(
                      width: 120,
                      height: 16,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.radiusSM),
                      ),
                    )
                  else
                    Text(
                      'Hello, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
