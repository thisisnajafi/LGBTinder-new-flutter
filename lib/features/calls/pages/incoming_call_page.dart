import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_icons.dart';
import '../presentation/widgets/call_blurred_backdrop.dart';
import '../presentation/widgets/call_outgoing_pulse.dart';
import '../providers/incoming_call_provider.dart';
import '../utils/call_navigation.dart';

/// Full-screen incoming call. Decline and Accept use the existing notifier
/// so an explicit decline still rejects, and accept still signals before
/// the permission prompt.
class IncomingCallPage extends ConsumerStatefulWidget {
  const IncomingCallPage({super.key});

  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage> {
  /// Cached in [initState] — [ref] must not be read from [dispose].
  IncomingCallNotifier? _incomingNotifier;

  @override
  void initState() {
    super.initState();
    _incomingNotifier = ref.read(incomingCallProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _incomingNotifier?.markIncomingPageOpen(true);
    });
  }

  /// Last call this page rendered; tells an answered call from a closed one
  /// once the provider state is already null.
  String? _lastCallId;
  bool _leaveScheduled = false;
  Timer? _answeredFallback;

  /// How long the accept path gets to replace this route before the page
  /// removes itself anyway (never leave an empty dark screen behind).
  static const Duration _answeredReplaceGrace = Duration(seconds: 2);

  @override
  void dispose() {
    _answeredFallback?.cancel();
    // Not markIncomingPageOpen(false): that notifies provider listeners
    // synchronously, which is not allowed while the tree is being torn down.
    _incomingNotifier?.markIncomingPageClosedOnDispose();
    super.dispose();
  }

  /// The call is gone (declined, cancelled by the caller, ring timeout,
  /// permission denied): remove this page instead of leaving it as an empty
  /// dark screen.
  ///
  /// This route is pushed imperatively, so `currentConfiguration.uri` still
  /// names the page underneath; [leaveIncomingCallRoute] checks the top of
  /// the match stack instead.
  void _scheduleLeave(GoRouter router) {
    if (_leaveScheduled) return;
    _leaveScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leaveScheduled = false;
      if (!mounted) return;
      if (ref.read(incomingCallProvider) != null) return;
      final callId = _lastCallId;
      final answered =
          callId != null && (_incomingNotifier?.wasAnswered(callId) ?? false);
      if (!answered) {
        leaveIncomingCallRoute(router);
        return;
      }
      // Answered: the accept path replaces this route with the in-call page.
      // Popping here could race that replacement and take the page below.
      _answeredFallback?.cancel();
      _answeredFallback = Timer(_answeredReplaceGrace, () {
        if (!mounted) return;
        if (ref.read(incomingCallProvider) != null) return;
        leaveIncomingCallRoute(router);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(incomingCallProvider);
    if (incoming == null) {
      _scheduleLeave(GoRouter.of(context));
      return const Scaffold(backgroundColor: AppColors.backgroundDark);
    }
    _lastCallId = incoming.callId;
    _answeredFallback?.cancel();
    _answeredFallback = null;

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
