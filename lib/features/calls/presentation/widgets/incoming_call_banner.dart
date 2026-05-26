import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../data/models/incoming_call_data.dart';
import '../../providers/incoming_call_provider.dart';
/// Foreground incoming call banner — slides down from top.
class IncomingCallBanner extends ConsumerStatefulWidget {
  final IncomingCallData callData;

  const IncomingCallBanner({
    super.key,
    required this.callData,
  });

  @override
  ConsumerState<IncomingCallBanner> createState() => _IncomingCallBannerState();
}

class _IncomingCallBannerState extends ConsumerState<IncomingCallBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _slideController = AnimationController(
      vsync: this,
      duration: AppAnimations.transitionModal,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppAnimations.curveDefault,
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
    final surface = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        elevation: 8,
        color: surface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingLG,
              vertical: AppSpacing.spacingMD,
            ),
            child: Row(
              children: [
                Semantics(
                  label: 'Caller avatar',
                  child: ClipOval(
                    child: widget.callData.callerAvatar != null
                        ? CachedNetworkImage(
                            imageUrl: widget.callData.callerAvatar!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: AppSvgIcon(
                              assetPath: AppIcons.userOutline,
                              size: 24,
                              color: textSecondary,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.callData.callerName,
                        style: AppTypography.titleMedium.copyWith(color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.callData.isVideo ? 'Incoming video call' : 'Incoming voice call',
                        style: AppTypography.bodySmall.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Decline call',
                  button: true,
                  child: _BannerActionButton(
                    icon: AppIcons.callMissed,
                    backgroundColor: AppColors.feedbackError,
                    onTap: () => ref.read(incomingCallProvider.notifier).reject(),
                  ),
                ),
                SizedBox(width: AppSpacing.spacingSM),
                Semantics(
                  label: 'Accept call',
                  button: true,
                  child: _BannerActionButton(
                    icon: widget.callData.isVideo
                        ? AppIcons.video
                        : AppIcons.phone,
                    backgroundColor: AppColors.feedbackSuccess,
                    onTap: () => ref.read(incomingCallProvider.notifier).accept(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerActionButton extends StatelessWidget {
  final String icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _BannerActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AppSvgIcon(
              assetPath: icon,
              size: 22,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Host widget: shows banner when [incomingCallProvider] has data and app is foreground.
class IncomingCallHost extends ConsumerWidget {
  final Widget child;

  const IncomingCallHost({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingCallProvider);
    final notifier = ref.read(incomingCallProvider.notifier);

    notifier.consumePendingNavigation(context);

    return Stack(
      children: [
        child,
        if (incoming != null && notifier.isAppForeground)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IncomingCallBanner(callData: incoming),
          ),
      ],
    );
  }
}
