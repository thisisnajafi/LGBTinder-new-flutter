import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spacing_constants.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profilePageCacheProvider);
    final greeting = _timeBasedGreeting();
    final profile = profileState.valueOrNull?.profile;
    final firstName = profile?.firstName;
    final avatarUrl = profile?.images?.isNotEmpty == true
        ? profile!.images!.first.imageUrl
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.contentPadding,
      ),
      child: Container(
        margin: const EdgeInsets.only(
          top: AppSpacing.spacingLG,
          bottom: AppSpacing.spacingLG,
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
                    onTap: () => context.goNamed('profile'),
                    child: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: ProfileImageWidget(
                          imageUrl: avatarUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
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
                  if (firstName == null || firstName.isEmpty)
                    const SkeletonLoader(
                      width: 80,
                      height: 14,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    )
                  else
                    Text(
                      'Hello, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
