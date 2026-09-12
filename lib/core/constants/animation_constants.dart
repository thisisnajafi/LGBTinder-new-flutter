// Animation durations and curves — minimal, app-wide
// Use these everywhere for consistent tap/transition timing.

import 'package:flutter/material.dart';

import '../providers/app_motion_prefs_provider.dart';

/// Centralized animation durations and curves.
/// Use for taps, page transitions, modals, list stagger, and feedback.
class AppAnimations {
  AppAnimations._();

  // --- Durations (ms) ---

  /// Button / icon press feedback. 120–150 ms.
  static const Duration tapDuration = Duration(milliseconds: 130);

  /// Push / pop page transitions. ~300 ms.
  static const Duration transitionPage = Duration(milliseconds: 300);

  /// Main shell bottom-nav tab changes. Snappy slide, no lag.
  static const Duration transitionTab = Duration(milliseconds: 200);

  /// Bottom sheet, dialog open/close. ~250 ms.
  static const Duration transitionModal = Duration(milliseconds: 250);

  /// Delay between list items on staggered appear. 40–60 ms per item.
  static const Duration listItemStagger = Duration(milliseconds: 50);

  /// Attachment grid cell stagger (CHAT-INPUT-002).
  static const Duration chatAttachGridStagger = Duration(milliseconds: 50);

  /// One attachment-grid cell fade/slide.
  static const Duration chatAttachGridCell = Duration(milliseconds: 220);

  /// Snackbar, validation, small feedback. 150–200 ms.
  static const Duration feedbackShort = Duration(milliseconds: 180);

  /// Chat / cached image blur → sharp (CHAT-IMG-003). Cap 200 ms.
  static const Duration imageFadeIn = Duration(milliseconds: 200);

  /// Cached image placeholder fade-out while the full frame appears.
  static const Duration imageFadeOut = Duration(milliseconds: 100);

  /// Chat read-receipt tick color (sent → read).
  static const Duration receiptTick = Duration(milliseconds: 300);

  /// Discovery card exit when advancing to next. ~200 ms.
  static const Duration cardExit = Duration(milliseconds: 200);

  /// Discovery card reveal when the next profile becomes top of stack.
  static const Duration cardReveal = Duration(milliseconds: 380);

  /// List item appear (fade + slide) for stagger. ~200 ms.
  static const Duration listItemAppear = Duration(milliseconds: 200);

  /// Conversation row implicit reorder / slide-to-top (CHAT-MSG-001).
  static const Duration chatListReorder = Duration(milliseconds: 350);

  /// Shared search-field debounce (PERF-INFRA-040). Empty queries fire immediately.
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Messenger search field height 0→56 (CHAT-MSG-003).
  static const Duration chatSearchField = Duration(milliseconds: 250);

  /// Open messenger search field height.
  static const double chatSearchFieldHeight = 56;

  /// Unread count pill bounce + digit slide (CHAT-MSG-002).
  static const Duration chatUnreadBadge = Duration(milliseconds: 250);

  /// Reaction chip pop-in (CHAT-FEAT-003).
  static const Duration chatReactionPop = Duration(milliseconds: 220);

  /// Scale at the start of a reaction chip pop.
  static const double chatReactionPopScaleBegin = 0.72;

  /// Overshoot then settle (Telegram-style chip).
  static const Curve chatReactionPopCurve = Curves.easeOutBack;

  /// Pinned-message bar height 0→48 (CHAT-FEAT-005).
  static const Duration chatPinnedBanner = Duration(milliseconds: 220);

  /// Open pinned bar height.
  static const double chatPinnedBannerHeight = 48;

  /// Peak scale of the unread pill bounce.
  static const double chatUnreadBadgeScaleBegin = 0.72;

  /// Undo window after hiding a conversation (CHAT-MSG-006).
  static const Duration chatListDeleteUndo = Duration(seconds: 5);

  /// Shimmer / skeleton loop. ~1–1.5 s, low contrast.
  static const Duration shimmerDuration = Duration(milliseconds: 1400);

  /// Snackbar / toast enter and exit. ~200 ms.
  static const Duration snackbarTransition = Duration(milliseconds: 200);

  /// Copied confirmation on the chat thread (CHAT-FEAT-002).
  static const Duration chatCopySnackbarHold = Duration(seconds: 2);

  /// How long a call-quality toast stays up (CALL-FEAT-005).
  static const Duration callQualityToastHold = Duration(seconds: 3);

  /// Minimum gap between call-quality toasts.
  static const Duration callQualityToastDebounce = Duration(seconds: 5);

  /// Outgoing-call concentric pulse (one ring cycle).
  static const Duration callOutgoingPulse = Duration(milliseconds: 1800);

  /// Delay between each outgoing-call pulse ring.
  static const Duration callOutgoingPulseStagger = Duration(milliseconds: 300);

  /// PiP snap to corner (elastic).
  static const Duration callPipSnap = Duration(milliseconds: 400);

  /// PiP snap when Reduce Motion is on.
  static const Duration callPipSnapReduced = Duration(milliseconds: 200);

  /// Scale while the local video PiP is being dragged.
  static const double callPipLiftScale = 1.05;

  /// PiP snap curve (overshoots then settles).
  static const Curve callPipSnapCurve = Curves.elasticOut;

  /// In-app incoming banner slide-down.
  static const Duration incomingBanner = Duration(milliseconds: 400);

  /// How long an in-app chat banner stays before auto-dismiss (CHAT-NOTIF-004).
  static const Duration inAppChatBannerHold = Duration(seconds: 4);

  /// Incoming banner entrance (overshoots then settles).
  static const Curve curveIncomingBanner = Curves.easeOutBack;

  /// Video-call HUD auto-hide after idle.
  static const Duration callHudIdle = Duration(seconds: 4);

  /// Video-call HUD fade (matches [transitionModal]).
  static const Duration callHudFade = Duration(milliseconds: 250);

  /// Ringing → connected: collapse rings, fade/scale stage, timer rise.
  static const Duration callConnect = Duration(milliseconds: 400);

  /// Timer slide-up distance while connecting (matches [AppSpacing.spacingMD]).
  static const double callConnectTimerSlide = 12.0;

  /// Remote video / avatar scale at the start of the connect transition.
  static const double callConnectStageBeginScale = 0.92;

  /// Pulse rings scale at the end of the connect collapse.
  static const double callConnectPulseEndScale = 0.6;

  /// New outgoing chat bubble enter (CHAT-THREAD-001 / CHAT-ANIM-001).
  static const Duration chatMessageSend = Duration(milliseconds: 220);

  /// Slide up from the composer: slight right + from below → zero.
  static const Offset chatMessageSendSlide = Offset(0.15, 0.3);

  /// Scale at the start of the outgoing enter animation.
  static const double chatMessageSendScaleBegin = 0.85;

  /// New incoming chat bubble enter (CHAT-THREAD-002 / CHAT-ANIM-002).
  static const Duration chatMessageReceive = Duration(milliseconds: 260);

  /// Slide in from the left, slightly from below → zero.
  static const Offset chatMessageReceiveSlide = Offset(-0.15, 0.1);

  /// Incoming bubble overshoots slightly then settles.
  static const Curve chatMessageReceiveCurve = Curves.easeOutBack;

  /// One typing-dot bounce cycle (CHAT-THREAD-003).
  static const Duration chatTypingDot = Duration(milliseconds: 900);

  /// Delay between each typing dot starting its bounce (Interval stagger).
  static const Duration chatTypingStagger = Duration(milliseconds: 150);

  /// Typing dot diameter.
  static const double chatTypingDotSize = 7;

  /// Peak [translateY] of a typing dot (up).
  static const double chatTypingDotBounce = 6;

  /// Peak scale of a typing dot (legacy pulse; bounce uses [chatTypingDotBounce]).
  static const double chatTypingDotScaleEnd = 1.5;

  /// Idle voice-waveform motion loop (CHAT-ANIM-011).
  static const Duration chatVoiceWaveformIdle = Duration(milliseconds: 900);

  /// Playback progress sample rate for the waveform painter.
  static const Duration chatVoiceWaveformTick = Duration(milliseconds: 100);

  /// Default bar count for chat voice waveforms.
  static const int chatVoiceWaveformBars = 22;

  /// Live bars while recording (CHAT-INPUT-003).
  static const int chatVoiceRecordBars = 30;

  /// Typing indicator hide / slide-out.
  static const Duration chatTypingExit = Duration(milliseconds: 200);

  /// Mic ↔ send icon morph (CHAT-INPUT-001).
  static const Duration chatSendMorph = Duration(milliseconds: 180);

  /// Scale at the start of the send-button morph.
  static const double chatSendMorphScaleBegin = 0.8;

  /// Morph curve (overshoot). Do not drive opacity with this.
  static const Curve chatSendMorphCurve = Curves.easeOutBack;

  /// Reply preview bar height 0→56 (CHAT-ANIM-007).
  static const Duration chatReplyPreview = Duration(milliseconds: 250);

  /// Collapsed / expanded height of the composer reply preview.
  static const double chatReplyPreviewHeight = 56;

  /// In-bubble reply quote height (CHAT-BUBBLE-005).
  static const double chatReplyQuoteHeight = 44;

  /// Accent bar on the quoted header.
  static const double chatReplyQuoteBarWidth = 3;

  /// Sent → delivered → read tick pulse (CHAT-ANIM-008).
  static const Duration chatStatusTickPulse = Duration(milliseconds: 200);

  /// Peak scale of a status-tick pulse.
  static const double chatStatusTickScalePeak = 1.3;

  /// Jump-to-bottom FAB scale in when scrolled up (CHAT-ANIM-009).
  static const Duration chatJumpToBottomIn = Duration(milliseconds: 200);

  /// Jump-to-bottom FAB scale out at the latest message.
  static const Duration chatJumpToBottomOut = Duration(milliseconds: 150);

  /// How long a quoted original stays washed after jump (CHAT-THREAD-006).
  static const Duration chatReplyHighlightHold = Duration(milliseconds: 800);

  /// Fade in/out of the reply-jump wash.
  static const Duration chatReplyHighlightFade = Duration(milliseconds: 150);

  /// Single-emoji / sticker send particle burst (CHAT-ANIM-004).
  static const Duration chatEmojiCelebration = Duration(milliseconds: 600);

  /// Message long-press floating menu (CHAT-ANIM-006).
  static const Duration chatContextMenu = Duration(milliseconds: 250);

  /// Scale-from-bubble curve for the context menu.
  static const Curve chatContextMenuCurve = Curves.easeOutBack;

  /// Backdrop blur behind the context menu.
  static const double chatContextMenuBlur = 3;

  /// Bubble lift while the long-press menu is open (CHAT-THREAD-007).
  static const double chatContextMenuBubbleScale = 1.05;

  /// Swipe-toward-center distance that arms reply (CHAT-ANIM-010).
  static const double chatSwipeReplyThreshold = 60;

  /// Extra stretch past the reply threshold so the bubble does not fly off.
  static const double chatSwipeReplyMax = 80;

  /// Snap-back after a swipe-to-reply gesture.
  static const Duration chatSwipeReplySpring = Duration(milliseconds: 280);

  /// Overshoots zero then settles (spring-like).
  static const Curve chatSwipeReplySpringCurve = Curves.easeOutBack;

  /// How strongly the reply SVG tracks the bubble (0 = pinned, 1 = glued).
  static const double chatSwipeReplyIconFollow = 0.45;

  /// Particle travel from the send button (60–80px).
  static const double chatEmojiCelebrationTravel = 72;

  /// Particles in the send celebration burst (3–5).
  static const int chatEmojiCelebrationParticles = 4;

  /// Tap → animateTo latest pixels (0 on a reverse thread).
  static const Duration chatJumpToBottomScroll = Duration(milliseconds: 300);

  /// New-message list overshoot when already at the latest row (CHAT-ANIM-013).
  static const Duration chatArrivalBounce = Duration(milliseconds: 300);

  /// How far the thread moves past the latest edge, then springs back.
  static const double chatArrivalBounceOvershoot = 12;

  /// Hang-up fade to black + summary card slide-up.
  static const Duration callEndFade = Duration(milliseconds: 300);

  /// How long the end-call summary stays up before the route pops.
  static const Duration callEndHold = Duration(seconds: 3);

  /// Reduce Motion: skip the fade and show the card briefly.
  static const Duration callEndHoldReduced = Duration(seconds: 1);

  /// Mute icon crossfade (mic ↔ mic-slash).
  static const Duration callMuteIconCrossfade = Duration(milliseconds: 150);

  /// Muted-button error-tint background.
  static const Duration callMuteTint = Duration(milliseconds: 200);

  /// Active-speaker avatar ring (one pulse cycle).
  static const Duration callSpeakingPulse = Duration(milliseconds: 400);

  /// Peak scale of the speaking ring (1.0 → this).
  static const double callSpeakingEndScale = 1.12;

  /// Starting opacity of the speaking ring (fades to 0).
  static const double callSpeakingStartOpacity = 0.8;

  /// Network quality bar fill / color tween.
  static const Duration callSignalBar = Duration(milliseconds: 300);

  // --- Curves ---

  /// Most transitions (push, modal, button release).
  static const Curve curveDefault = Curves.easeOutCubic;

  /// Where a bit more motion is acceptable (e.g. dialog scale-in).
  static const Curve curveEmphasized = Curves.easeInOutCubic;

  // --- Scale ---

  /// Scale factor on button/icon press (1 → this value).
  static const double buttonPressScale = 0.97;

  /// Optional: respect reduce-motion. Pass from build(context).
  /// OS accessibility AND the persisted in-app flag (PERF-SCR-A11Y-001).
  static bool animationsEnabled(BuildContext context) {
    if (AppMotionPreferences.reduceMotion) return false;
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// Returns [tapDuration] if animations are enabled, otherwise [Duration.zero].
  static Duration effectiveTapDuration(BuildContext context) {
    return animationsEnabled(context) ? tapDuration : Duration.zero;
  }

  /// Push / onboarding page slide; [Duration.zero] when Reduce Motion is on.
  static Duration pageTransitionDuration(BuildContext context) {
    return animationsEnabled(context) ? transitionPage : Duration.zero;
  }

  /// Full-image fade-in; [Duration.zero] when Reduce Motion is on.
  static Duration imageFadeDuration(BuildContext context) {
    return animationsEnabled(context) ? imageFadeIn : Duration.zero;
  }

  /// Placeholder fade-out paired with [imageFadeDuration].
  static Duration imageFadeOutDuration(BuildContext context) {
    return animationsEnabled(context) ? imageFadeOut : Duration.zero;
  }

  /// Conversation list reorder; [Duration.zero] when Reduce Motion is on.
  static Duration chatListReorderDuration(BuildContext context) {
    return animationsEnabled(context) ? chatListReorder : Duration.zero;
  }

  /// Messenger search field; [Duration.zero] when Reduce Motion is on.
  static Duration chatSearchFieldDuration(BuildContext context) {
    return animationsEnabled(context) ? chatSearchField : Duration.zero;
  }

  /// Unread badge bounce; [Duration.zero] when Reduce Motion is on.
  static Duration chatUnreadBadgeDuration(BuildContext context) {
    return animationsEnabled(context) ? chatUnreadBadge : Duration.zero;
  }

  /// Reaction chip pop; [Duration.zero] when Reduce Motion is on.
  static Duration chatReactionPopDuration(BuildContext context) {
    return animationsEnabled(context) ? chatReactionPop : Duration.zero;
  }

  /// Pinned bar 0→48; [Duration.zero] when Reduce Motion is on.
  static Duration chatPinnedBannerDuration(BuildContext context) {
    return animationsEnabled(context) ? chatPinnedBanner : Duration.zero;
  }

  /// Conversation swipe dismiss; [Duration.zero] when Reduce Motion is on.
  static Duration chatListSwipeDuration(BuildContext context) {
    return animationsEnabled(context) ? transitionPage : Duration.zero;
  }

  /// Mic ↔ send morph; [Duration.zero] when Reduce Motion is on.
  static Duration chatSendMorphDuration(BuildContext context) {
    return animationsEnabled(context) ? chatSendMorph : Duration.zero;
  }

  /// Attach-grid cell motion; [Duration.zero] when Reduce Motion is on.
  static Duration chatAttachGridDuration(BuildContext context) {
    return animationsEnabled(context) ? chatAttachGridCell : Duration.zero;
  }

  /// Composer reply preview; [Duration.zero] when Reduce Motion is on.
  static Duration chatReplyPreviewDuration(BuildContext context) {
    return animationsEnabled(context) ? chatReplyPreview : Duration.zero;
  }

  /// Scroll to a quoted original; [Duration.zero] when Reduce Motion is on.
  static Duration chatJumpToReplyDuration(BuildContext context) {
    return animationsEnabled(context) ? chatJumpToBottomScroll : Duration.zero;
  }

  /// Reply-jump highlight fade; [Duration.zero] when Reduce Motion is on.
  static Duration chatReplyHighlightFadeDuration(BuildContext context) {
    return animationsEnabled(context) ? chatReplyHighlightFade : Duration.zero;
  }
}
