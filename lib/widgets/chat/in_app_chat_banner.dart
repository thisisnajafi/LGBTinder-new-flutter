import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/profile_image_widget.dart';
import '../../features/chat/providers/in_app_chat_banner_provider.dart';
import '../../features/chat/utils/in_app_chat_banner.dart';
import '../../shared/services/notification_navigation.dart';

/// Telegram-style 72px slide-down banner for another conversation.
class InAppChatMessageBanner extends ConsumerStatefulWidget {
  const InAppChatMessageBanner({
    super.key,
    required this.item,
    this.onTap,
    this.onDismissed,
  });

  static const double height = 72;
  static const double avatarSize = 44;

  final InAppChatBannerItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  @override
  ConsumerState<InAppChatMessageBanner> createState() =>
      _InAppChatMessageBannerState();
}

class _InAppChatMessageBannerState extends ConsumerState<InAppChatMessageBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  double _dragDy = 0;

  @override
  void initState() {
    super.initState();
    final disableAnimations = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _slideController = AnimationController(
      vsync: this,
      duration: AppAnimations.incomingBanner,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppAnimations.curveIncomingBanner,
    ));
    if (!disableAnimations) {
      _slideController.forward();
    } else {
      _slideController.value = 1;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragDy < 0 ? _dragDy : 0),
          child: Material(
            color: surface,
            elevation: 6,
            child: Semantics(
              button: true,
              label: '${widget.item.title}: ${widget.item.body}',
              child: SizedBox(
                key: ValueKey('in-app-chat-banner-body-${widget.item.id}'),
                height: InAppChatMessageBanner.height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingLG,
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: InAppChatMessageBanner.avatarSize,
                          height: InAppChatMessageBanner.avatarSize,
                          child: ProfileImageWidget(
                            imageUrl: widget.item.avatarUrl,
                            userId: widget.item.peerUserId,
                            width: InAppChatMessageBanner.avatarSize,
                            height: InAppChatMessageBanner.avatarSize,
                            fit: BoxFit.cover,
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusRound),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              widget.item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                            ),
                            AppText(
                              widget.item.body,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: textSecondary,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragDy += details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDy < -24 || velocity < -300) {
      widget.onDismissed?.call();
      return;
    }
    setState(() => _dragDy = 0);
  }
}

/// App-wide stack (max 2) of in-app chat banners.
class InAppChatBannerHost extends ConsumerWidget {
  const InAppChatBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inAppChatBannerProvider);

    return Stack(
      children: [
        child,
        if (items.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in items.reversed)
                    InAppChatMessageBanner(
                      key: ValueKey(item.id),
                      item: item,
                      onDismissed: () => ref
                          .read(inAppChatBannerProvider.notifier)
                          .dismiss(item.id),
                      onTap: () {
                        ref
                            .read(inAppChatBannerProvider.notifier)
                            .dismiss(item.id);
                        final router = GoRouter.maybeOf(context);
                        if (router == null) return;
                        NotificationNavigation.navigateWithRouter(
                          router,
                          data: {
                            'type': item.type,
                            if (item.peerUserId > 0) 'user_id': item.peerUserId,
                            'user_name': item.title,
                            if (item.avatarUrl != null)
                              'avatar_url': item.avatarUrl,
                            ...item.routeData,
                          },
                          usePush: true,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
