import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/providers/startup_flow_provider.dart';
import '../../../../core/widgets/profile_image_widget.dart';
import '../../../../shared/services/agora_service.dart';
import '../../../../shared/services/push_notification_service.dart';
import '../../data/models/active_call_notification.dart';
import '../../data/models/incoming_call_data.dart';
import '../../providers/active_call_session_provider.dart';
import '../../providers/incoming_call_provider.dart';
import '../../utils/call_navigation.dart';
import '../../../../shared/services/call_permissions.dart';
import 'call_permission_sheet.dart';

/// Foreground incoming call banner — slides down from top.
///
/// Content row is avatar + padding = 80px (48 + [AppSpacing.spacingLG] × 2).
/// Full-screen call UI opens only after accept.
class IncomingCallBanner extends ConsumerStatefulWidget {
  static const double avatarSize = 48;

  static double get contentHeight => avatarSize + AppSpacing.spacingLG * 2;

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
    // Do not use MediaQuery/Theme here — that depends on InheritedWidgets
    // before initState completes and crashes the Calls tab overlay.
    final disableAnimations =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
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
          child: SizedBox(
            key: const ValueKey('incoming-call-banner-body'),
            height: IncomingCallBanner.contentHeight,
            child: Padding(
              padding: ResponsivePadding.horizontal(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Caller avatar',
                    child: ClipOval(
                      child: SizedBox(
                        width: IncomingCallBanner.avatarSize,
                        height: IncomingCallBanner.avatarSize,
                        child: ProfileImageWidget(
                          imageUrl: widget.callData.callerAvatar,
                          userId: widget.callData.callerId,
                          width: IncomingCallBanner.avatarSize,
                          height: IncomingCallBanner.avatarSize,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusRound,
                          ),
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
                      AppText(
                        widget.callData.callerName,
                        style: AppTypography.titleMedium.copyWith(color: textPrimary),
                        maxLines: 1,
                      ),
                      AppText(
                        widget.callData.isVideo ? 'Incoming video call' : 'Incoming voice call',
                        style: AppTypography.bodySmall.copyWith(color: textSecondary),
                        maxLines: 1,
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

/// Host widget: foreground incoming is the banner only. Full-screen
/// [OutgoingCallPage] opens after accept.
class IncomingCallHost extends ConsumerStatefulWidget {
  final Widget child;

  const IncomingCallHost({super.key, required this.child});

  @override
  ConsumerState<IncomingCallHost> createState() => _IncomingCallHostState();
}

class _IncomingCallHostState extends ConsumerState<IncomingCallHost> {
  bool _showingPermissionSheet = false;

  @override
  void initState() {
    super.initState();
    ActiveCallBridge.handle = _onActiveCallNotification;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ActiveCallBridge.consumePending();
      if (!ref.read(startupFlowCompleteProvider)) return;
      ref.read(incomingCallProvider.notifier).consumePendingNavigation(context);
    });
  }

  @override
  void dispose() {
    ActiveCallBridge.handle = null;
    super.dispose();
  }

  void _onActiveCallNotification(String? actionId, String? payload) {
    if (ActiveCallNotification.isHangupAction(actionId)) {
      final decoded = ActiveCallNotification.decode(payload);
      final callId = int.tryParse(decoded?['call_id']?.toString() ?? '') ?? 0;
      unawaited(
        ref.read(activeCallSessionProvider.notifier).hangUpFromSystem(
              callIdOverride: callId > 0 ? callId : null,
            ),
      );
      return;
    }

    final session = ref.read(activeCallSessionProvider);
    if (session != null) {
      if (!mounted) return;
      restoreActiveCallRoute(GoRouter.of(context), session);
      return;
    }

    if (!AgoraService().isInCall) {
      unawaited(PushNotificationService().hideActiveCall());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(startupFlowCompleteProvider, (previous, next) {
      if (!next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(incomingCallProvider.notifier).consumePendingNavigation(context);
      });
    });
    ref.listen(incomingCallProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = ref.read(incomingCallProvider.notifier);
        if (notifier.hasPendingNavigation &&
            ref.read(startupFlowCompleteProvider)) {
          notifier.consumePendingNavigation(context);
        }
        if (notifier.hasBlockedPermission &&
            ref.read(startupFlowCompleteProvider) &&
            !_showingPermissionSheet) {
          unawaited(_showBlockedPermissionSheet());
        }
      });
    });

    return Stack(
      children: [
        widget.child,
        const _IncomingCallForegroundLayer(),
      ],
    );
  }

  Future<void> _showBlockedPermissionSheet() async {
    if (!mounted || _showingPermissionSheet) return;
    final notifier = ref.read(incomingCallProvider.notifier);
    final result = notifier.blockedPermission;
    if (result == null) return;
    _showingPermissionSheet = true;
    await CallPermissionSheet.show(
      context,
      video: notifier.blockedPermissionVideo,
      permanentlyDenied: result == CallPermissionResult.permanentlyDenied,
    );
    notifier.clearBlockedPermission();
    if (mounted) {
      setState(() => _showingPermissionSheet = false);
    } else {
      _showingPermissionSheet = false;
    }
  }
}

/// Overlay sibling of the app child so incoming state does not rebuild the
/// navigator tree (PERF-COMP-CALL-005 / PERF-COMP-SHARED-004).
class _IncomingCallForegroundLayer extends ConsumerWidget {
  const _IncomingCallForegroundLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingCallProvider);
    final notifier = ref.read(incomingCallProvider.notifier);
    final minimized = ref.watch(activeCallSessionProvider);

    if (incoming != null && notifier.isAppForeground) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: RepaintBoundary(
          child: IncomingCallBanner(callData: incoming),
        ),
      );
    }
    if (minimized != null && minimized.minimized) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: MinimizedCallReturnBanner(
            peerName: minimized.peerName,
            isVideo: minimized.isVideo,
            onTap: () => restoreActiveCallRoute(
              GoRouter.of(context),
              minimized,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// In-app return banner while the Agora session is minimized.
class MinimizedCallReturnBanner extends StatelessWidget {
  final String peerName;
  final bool isVideo;
  final VoidCallback onTap;

  const MinimizedCallReturnBanner({
    super.key,
    required this.peerName,
    required this.isVideo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = 'Active call with $peerName';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacingMD,
        AppSpacing.spacingSM,
        AppSpacing.spacingMD,
        AppSpacing.spacingSM,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          child: Semantics(
            button: true,
            label: label,
            child: Ink(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppRadius.radiusLG),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingSM,
                  ),
                  child: Row(
                    children: [
                      AppSvgIcon(
                        assetPath: isVideo ? AppIcons.video : AppIcons.call,
                        size: 20,
                        color: AppColors.textPrimaryDark,
                      ),
                      const SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.textPrimaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              'Tap to return',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimaryDark
                                        .withValues(alpha: 0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      AppSvgIcon(
                        assetPath: AppIcons.arrowRight,
                        size: 18,
                        color: AppColors.textPrimaryDark,
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
}
