import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/calls/data/models/call.dart';
import '../../features/chat/presentation/widgets/chat_muted_banner.dart';
import '../../features/chat/providers/chat_pinned_banner_provider.dart';
import '../../features/chat/providers/conversation_mute_cache_provider.dart';
import '../../features/calls/pages/outgoing_call_page.dart';
import '../../features/calls/utils/call_navigation.dart';
import 'chat_arrival_bounce_layer.dart';
import 'chat_composer_bar.dart';
import 'chat_connection_banner.dart';
import 'chat_header.dart';
import 'chat_keyboard_inset_pad.dart';
import 'chat_message_list.dart';
import 'chat_message_list_tile.dart';
import 'pinned_messages_banner.dart';

/// Header + timeline + composer chrome (PERF-PAGE-CHAT-009).
class ChatThreadPageShell extends ConsumerWidget {
  const ChatThreadPageShell({
    super.key,
    required this.peerUserId,
    required this.peerDisplayName,
    required this.peerAvatarUrl,
    required this.peerCallPhotoUrl,
    required this.currentUserId,
    required this.embedded,
    required this.scrollController,
    required this.threadListKey,
    required this.unreadSeparatorKey,
    required this.showUnreadSeparator,
    required this.openUnreadCount,
    required this.chatBgAsset,
    required this.onLeave,
    required this.onHeaderTap,
    required this.onVideoCall,
    required this.onPinnedBannerTap,
    required this.onRetryLoad,
    required this.onRetryLoadOlder,
    required this.onSend,
    required this.onJumpToLatest,
    required this.onRedialCall,
    required this.onRetryFailed,
    required this.onReply,
    required this.onJumpToReply,
    required this.onReact,
    required this.onLongPress,
    required this.onSelfDestructTap,
    required this.onImageTap,
    required this.onVideoTap,
    required this.onVoiceListened,
    required this.onMediaTap,
    required this.onMediaLongPress,
    required this.onVoiceRecordStart,
    required this.onVoiceRecordSend,
    required this.onVoiceRecordCancel,
    required this.onTextChanged,
    required this.onFocusChange,
    required this.onKeyboardInset,
    required this.onKeyboardInsetTick,
    required this.onKeyboardInsetSettled,
  });

  static const backgroundLight = 'assets/images/chat/chat-light.png';
  static const backgroundDark = 'assets/images/chat/chat-dark.png';

  final int peerUserId;
  final String peerDisplayName;
  final String? peerAvatarUrl;
  final String? peerCallPhotoUrl;
  final int currentUserId;
  final bool embedded;
  final ScrollController scrollController;
  final GlobalKey threadListKey;
  final GlobalKey unreadSeparatorKey;
  final bool showUnreadSeparator;
  final int openUnreadCount;
  final String chatBgAsset;
  final VoidCallback onLeave;
  final VoidCallback onHeaderTap;
  final VoidCallback onVideoCall;
  final VoidCallback onPinnedBannerTap;
  final VoidCallback onRetryLoad;
  final VoidCallback onRetryLoadOlder;
  final ValueChanged<String> onSend;
  final VoidCallback onJumpToLatest;
  final ValueChanged<Call> onRedialCall;
  final void Function(Map<String, dynamic> message) onRetryFailed;
  final void Function(Map<String, dynamic> message) onReply;
  final void Function(Map<String, dynamic> message) onJumpToReply;
  final void Function(Map<String, dynamic> message, String emoji) onReact;
  final ChatMessageLongPressCallback onLongPress;
  final void Function(Map<String, dynamic> message) onSelfDestructTap;
  final void Function(Map<String, dynamic> message) onImageTap;
  final void Function(Map<String, dynamic> message) onVideoTap;
  final void Function(Map<String, dynamic> message) onVoiceListened;
  final VoidCallback onMediaTap;
  final VoidCallback onMediaLongPress;
  final Future<bool> Function() onVoiceRecordStart;
  final Future<void> Function() onVoiceRecordSend;
  final Future<void> Function() onVoiceRecordCancel;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<double> onKeyboardInset;
  final VoidCallback onKeyboardInsetTick;
  final VoidCallback onKeyboardInsetSettled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final muted = ref.watch(
      conversationMuteCacheProvider.select((ids) => ids.contains(peerUserId)),
    );
    final router = GoRouter.maybeOf(context);
    final canPopRoute =
        (router?.canPop() ?? false) || Navigator.of(context).canPop();

    return PopScope(
      canPop: embedded ? false : canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onLeave();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  image: DecorationImage(
                    image: AssetImage(chatBgAsset),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: ChatKeyboardInsetPad(
                onBottomInsetChanged: onKeyboardInset,
                onInsetTick: onKeyboardInsetTick,
                onInsetAnimationEnd: onKeyboardInsetSettled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChatHeader(
                      userId: peerUserId,
                      name: peerDisplayName,
                      avatarUrl: peerAvatarUrl,
                      onBack: onLeave,
                      onHeaderTap: onHeaderTap,
                      onInfo: onHeaderTap,
                      onCall: () {
                        startOutgoingCall(
                          context: context,
                          ref: ref,
                          recipientId: peerUserId,
                          recipientName: peerDisplayName,
                          recipientAvatarUrl: peerCallPhotoUrl,
                          type: OutgoingCallType.voice,
                        );
                      },
                      onVideoCall: onVideoCall,
                    ),
                    const ChatConnectionBanner(),
                    if (muted) const ChatMutedBanner(),
                    Expanded(
                      child: Column(
                        children: [
                          _PinnedMessagesBannerSection(
                            userId: peerUserId,
                            onTap: onPinnedBannerTap,
                          ),
                          Expanded(
                            child: ChatArrivalBounceLayer(
                              peerUserId: peerUserId,
                              child: ChatMessageList(
                                peerUserId: peerUserId,
                                peerDisplayName: peerDisplayName,
                                currentUserId: currentUserId,
                                scrollController: scrollController,
                                threadListKey: threadListKey,
                                unreadSeparatorKey: unreadSeparatorKey,
                                showUnreadSeparator: showUnreadSeparator,
                                openUnreadCount: openUnreadCount,
                                onRetryLoad: onRetryLoad,
                                onRetryLoadOlder: onRetryLoadOlder,
                                onSendOpener: onSend,
                                onJumpToLatest: onJumpToLatest,
                                onRedialCall: onRedialCall,
                                onRetryFailed: onRetryFailed,
                                onReply: onReply,
                                onJumpToReply: onJumpToReply,
                                onReact: onReact,
                                onLongPress: onLongPress,
                                onSelfDestructTap: onSelfDestructTap,
                                onImageTap: onImageTap,
                                onVideoTap: onVideoTap,
                                onVoiceListened: onVoiceListened,
                              ),
                            ),
                          ),
                          ChatComposerBar(
                            peerUserId: peerUserId,
                            onSend: onSend,
                            onMediaTap: onMediaTap,
                            onMediaLongPress: onMediaLongPress,
                            onVoiceRecordStart: onVoiceRecordStart,
                            onVoiceRecordSend: onVoiceRecordSend,
                            onVoiceRecordCancel: onVoiceRecordCancel,
                            onTextChanged: onTextChanged,
                            onFocusChange: onFocusChange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedMessagesBannerSection extends ConsumerWidget {
  final int userId;
  final VoidCallback onTap;

  const _PinnedMessagesBannerSection({
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(chatPinnedBannerProvider(userId));
    return PinnedMessagesBanner(
      pinnedCount: snapshot.count,
      preview: snapshot.preview,
      onTap: onTap,
    );
  }
}
