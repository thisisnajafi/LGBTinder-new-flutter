import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/profile_image_widget.dart';
import '../../providers/agora_rtc_session_provider.dart';
import '../../providers/live_call_ui_provider.dart';
import 'call_outgoing_pulse.dart';
import 'call_speaking_ring.dart';

enum CallSpeakingTarget { none, local, remote }

/// Profile photo + caption when a camera is off (video mute or voice call).
class CallStagePlaceholder extends ConsumerWidget {
  final String? imageUrl;
  final int userId;
  final String caption;
  final bool compact;
  final bool pulse;
  final CallSpeakingTarget speakingTarget;

  const CallStagePlaceholder({
    super.key,
    required this.userId,
    this.imageUrl,
    this.caption = 'Camera is off',
    this.compact = false,
    this.pulse = false,
    this.speakingTarget = CallSpeakingTarget.none,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarSize = compact ? 48.0 : 120.0;
    final localMuted = ref.watch(isMutedProvider);
    final remoteMuted = ref.watch(agoraRtcSessionProvider).remoteAudioMuted;
    final muted = switch (speakingTarget) {
      CallSpeakingTarget.local => localMuted,
      CallSpeakingTarget.remote => remoteMuted,
      CallSpeakingTarget.none => false,
    };
    final speaking = switch (speakingTarget) {
      CallSpeakingTarget.local =>
        ref.watch(localSpeakingProvider) && !localMuted,
      CallSpeakingTarget.remote =>
        ref.watch(remoteSpeakingProvider) && !remoteMuted,
      CallSpeakingTarget.none => false,
    };
    final avatar = ClipOval(
      child: SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: ProfileImageWidget(
          imageUrl: imageUrl,
          userId: userId,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(avatarSize / 2),
        ),
      ),
    );

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacingSM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pulse && !compact)
                CallOutgoingPulseAvatar(
                  active: true,
                  userId: userId,
                  imageUrl: imageUrl,
                  avatarSize: avatarSize,
                )
              else
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CallSpeakingRing(
                      active: speaking,
                      diameter: avatarSize,
                      child: avatar,
                    ),
                    if (muted && !compact)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CallMutedMicBadge(compact: compact),
                      ),
                  ],
                ),
              SizedBox(
                height: compact ? AppSpacing.spacingXS : AppSpacing.spacingMD,
              ),
              if (!compact)
                AppSvgIcon(
                  assetPath: AppIcons.cameraSlash,
                  size: 22,
                  color: AppColors.textPrimaryDark.withValues(alpha: 0.85),
                ),
              if (!compact) const SizedBox(height: AppSpacing.spacingXS),
              Text(
                caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: (compact
                        ? AppTypography.labelSmall
                        : AppTypography.labelMedium)
                    .copyWith(color: AppColors.textPrimaryDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muted-microphone mark shown on a call participant.
class CallMutedMicBadge extends StatelessWidget {
  final bool compact;

  const CallMutedMicBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 22.0 : 36.0;
    return Semantics(
      label: 'Microphone muted',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.feedbackError.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: compact ? 1 : 2),
        ),
        alignment: Alignment.center,
        child: AppSvgIcon(
          assetPath: AppIcons.microphoneSlash,
          size: compact ? 12 : 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Watches local or remote mute and paints [CallMutedMicBadge].
class CallParticipantMuteBadge extends ConsumerWidget {
  final bool local;
  final bool compact;

  const CallParticipantMuteBadge({
    super.key,
    required this.local,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = local
        ? ref.watch(isMutedProvider)
        : ref.watch(agoraRtcSessionProvider).remoteAudioMuted;
    if (!muted) return const SizedBox.shrink();
    return CallMutedMicBadge(compact: compact);
  }
}
