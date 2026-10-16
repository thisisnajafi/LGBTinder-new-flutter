import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_icons.dart';
import '../../../routes/app_router.dart';
import '../presentation/widgets/call_blurred_backdrop.dart';
import '../presentation/widgets/call_outgoing_pulse.dart';
import '../providers/incoming_call_provider.dart';

/// Full-screen incoming call. Decline and Accept use the existing notifier
/// so an explicit decline still rejects, and accept still signals before
/// the permission prompt.
class IncomingCallPage extends ConsumerStatefulWidget {
  const IncomingCallPage({super.key});

  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(incomingCallProvider.notifier).markIncomingPageOpen(true);
    });
  }

  @override
  void dispose() {
    ref.read(incomingCallProvider.notifier).markIncomingPageOpen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(incomingCallProvider);
    if (incoming == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final path =
            GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
        if (path == AppRoutes.incomingCall && context.canPop()) {
          context.pop();
        }
      });
      return const Scaffold(backgroundColor: AppColors.backgroundDark);
    }

    final kind = incoming.isVideo ? 'video' : 'voice';
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CallBlurredBackdrop(
            userId: incoming.callerId,
            imageUrl: incoming.callerAvatar,
          ),
          SafeArea(
            child: ResponsiveCenter(
              maxWidth: 480,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < AppBreakpoints.compact;
                  final available = constraints.maxHeight.isFinite
                      ? (constraints.maxHeight - (AppSpacing.spacingLG * 2))
                          .clamp(0.0, double.infinity)
                      : 0.0;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.spacingLG),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: available),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CallOutgoingPulseAvatar(
                            active: true,
                            userId: incoming.callerId,
                            imageUrl: incoming.callerAvatar,
                            avatarSize: compact ? 120 : 176,
                          ),
                          const SizedBox(height: AppSpacing.spacingLG),
                          ClampedTextScale(
                            child: Text(
                              incoming.callerName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingSM),
                          Text(
                            'Incoming $kind call',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingXXL),
                          Row(
                            children: [
                              Expanded(
                                child: _IncomingActionButton(
                                  label: 'Decline',
                                  icon: AppIcons.callMissed,
                                  background: AppColors.feedbackError,
                                  onTap: () => ref
                                      .read(incomingCallProvider.notifier)
                                      .reject(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.spacingMD),
                              Expanded(
                                child: _IncomingActionButton(
                                  label: 'Accept',
                                  icon: incoming.isVideo
                                      ? AppIcons.video
                                      : AppIcons.call,
                                  background: AppColors.feedbackSuccess,
                                  onTap: () => ref
                                      .read(incomingCallProvider.notifier)
                                      .accept(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingActionButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color background;
  final VoidCallback onTap;

  const _IncomingActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingSM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcon(
                    assetPath: icon,
                    size: 22,
                    color: AppColors.textPrimaryDark,
                  ),
                  const SizedBox(width: AppSpacing.spacingSM),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.button.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
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
