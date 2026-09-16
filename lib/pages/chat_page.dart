// Screen: ChatPage
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../core/constants/animation_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_date_time.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_action_bottom_sheet.dart';
import '../widgets/chat/chat_message_context_menu.dart';
import '../widgets/chat/chat_forward_sheet.dart';
import '../widgets/chat/chat_thread_page_shell.dart';
import '../widgets/chat/chat_date_badge.dart';
import '../widgets/chat/chat_unread_separator_bar.dart';
import '../widgets/chat/chat_video_viewer.dart';
import 'chat_conversation_info_page.dart';
import '../features/chat/providers/conversation_mute_cache_provider.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/chat/data/services/chat_outbound_queue_service.dart';
import '../features/chat/providers/chat_outbox_ui_provider.dart';
import '../features/chat/utils/chat_outbox_ui.dart';
import '../features/chat/data/local/chat_info_cache.dart';
import '../features/chat/data/models/message.dart';
import '../features/chat/utils/chat_visual_media.dart';
import '../features/chat/utils/chat_client_id.dart';
import '../features/chat/utils/chat_optimistic.dart';
import '../features/chat/utils/chat_message_enter_gate.dart';
import '../features/chat/utils/chat_delivery_status_map.dart';
import '../features/chat/utils/chat_send_retry.dart';
import '../features/chat/utils/chat_edited_apply.dart';
import '../features/chat/utils/self_destruct_send.dart';
import '../features/chat/data/models/message_delivery_status.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../features/chat/presentation/widgets/chat_upgrade_widgets.dart';
import '../features/chat/presentation/widgets/self_destruct_viewer.dart';
import '../features/chat/providers/chat_thread_providers.dart';
import '../features/chat/providers/chat_thread_live_sync_provider.dart';
import '../features/chat/providers/chat_pusher_providers.dart';
import '../features/chat/utils/chat_thread_remote_ingest.dart';
import '../features/chat/providers/chat_active_backend_sync_provider.dart';
import '../features/chat/providers/active_chat_peer_bridge.dart';
import '../shared/services/pusher_websocket_service.dart';
import '../features/payments/data/services/plan_limits_service.dart';
import '../features/user/providers/user_providers.dart';
import '../features/profile/presentation/widgets/own_profile/profile_photo_utils.dart';
import '../features/profile/providers/profile_providers.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../shared/utils/plan_guard.dart';
import '../features/calls/data/models/call.dart';
import '../features/calls/pages/outgoing_call_page.dart';
import '../features/calls/providers/call_providers.dart';
import '../features/calls/data/local/call_history_local_cache.dart';
import '../features/calls/providers/messenger_calls_provider.dart';
import '../features/calls/utils/call_log_labels.dart';
import '../features/chat/providers/chat_list_preview_provider.dart';
import '../features/chat/providers/chat_image_upload_progress_provider.dart';
import '../features/chat/providers/user_presence_cache_provider.dart';
import '../features/chat/utils/chat_message_preview.dart';
import '../features/chat/utils/chat_image_placeholder.dart';
import '../features/chat/utils/chat_gallery_items.dart';
import '../features/chat/providers/pinned_count_provider.dart';
import '../features/chat/providers/chat_pinned_banner_provider.dart';
import '../features/chat/data/services/chat_service.dart';
import '../features/chat/data/local/chat_local_repository.dart';
import '../features/chat/utils/chat_timeline_merger.dart';
import '../features/chat/utils/chat_thread_local_apply.dart';
import '../features/chat/utils/chat_thread_row_map.dart';
import '../features/chat/utils/chat_call_timeline.dart';
import '../features/chat/utils/chat_load_older.dart';
import '../features/chat/utils/chat_message_sheet_actions.dart';
import '../features/chat/utils/chat_copy_feedback.dart';
import '../features/chat/utils/chat_delete_confirm.dart';
import '../features/chat/utils/chat_reply_jump.dart';
import '../features/chat/utils/chat_reaction_summary.dart';
import '../features/chat/utils/chat_video_playback.dart';
import '../features/chat/utils/chat_unread_separator.dart';
import '../features/safety/presentation/screens/report_user_screen.dart';
import '../features/chat/utils/chat_unseen_incoming.dart';
import '../features/chat/utils/chat_arrival_bounce.dart';
import '../features/chat/utils/chat_thread_scroll.dart';
import '../features/chat/utils/chat_timeline_slots.dart';
import '../features/chat/utils/chat_keyboard_anchor.dart';
import '../features/chat/utils/chat_typing_outbound.dart';
import '../widgets/chat/chat_attachment_sheet.dart';
import '../widgets/chat/chat_media_permission_sheet.dart';
import '../features/chat/utils/chat_media_permissions.dart';
import '../features/chat/utils/chat_reconnect_catch_up.dart';
import '../features/chat/presentation/widgets/share_profile_sheet.dart';
import '../features/chat/utils/chat_attachment_kind.dart';
import 'package:file_picker/file_picker.dart';
import '../features/calls/utils/call_navigation.dart';
import '../features/calls/utils/call_redial_confirm.dart';
import '../routes/app_router.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';
import '../core/cache/peer_avatar_cache.dart';
import '../core/utils/media_url.dart';
import '../core/responsive/responsive.dart';

/// Chat page - Individual chat conversation screen
class ChatPage extends ConsumerStatefulWidget {
  final int userId;
  final String? userName;
  final String? avatarUrl;
  final bool embedded;
  final VoidCallback? onEmbeddedClose;

  const ChatPage({
    Key? key,
    required this.userId,
    this.userName,
    this.avatarUrl,
    this.embedded = false,
    this.onEmbeddedClose,
  }) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  static const int _historyPageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _threadListKey = GlobalKey();
  final GlobalKey _unreadSeparatorKey = GlobalKey();
  int _openUnreadCount = 0;
  bool _showUnreadSeparator = false;
  bool _hasMoreMessages = true;
  ChatHistoryCursor? _nextCursor;
  int? _currentUserId;

  ChatThreadMessagesNotifier get _thread => _threadNotifier;

  ChatThreadMessagesState get _threadState =>
      ref.read(chatThreadMessagesProvider(widget.userId));

  List<Map<String, dynamic>> get _messages => _threadState.rows;

  /// Writes through to [chatThreadMessagesProvider] (PERF-INFRA-013).
  set _messages(List<Map<String, dynamic>> value) => _thread.setRows(value);

  ChatMessageEnterGate get _enterGate => _thread.enterGate;

  bool get _isLoading => _threadState.isLoading;

  bool get _isLoadingMore => _threadState.isLoadingMore;

  bool get _loadMoreFailed => _threadState.loadMoreFailed;

  ChatComposerNotifier get _composer =>
      ref.read(chatComposerProvider(widget.userId).notifier);

  ChatComposerState get _composerState =>
      ref.read(chatComposerProvider(widget.userId));

  int? get _editingMessageId => _composerState.editingMessageId;

  int? get _repliedToMessageId => _composerState.replyMessageId;

  String? get _repliedToMessage => _composerState.replyText;

  String? get _repliedToName => _composerState.replyName;

  // Pusher real-time state
  int? _conversationId;
  StreamSubscription<CallSignalingEvent>? _callEventSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;
  StreamSubscription<List<Message>>? _localMessagesSubscription;
  Timer? _realtimeFallbackTimer;
  String? _resolvedUserName;
  String? _resolvedAvatarUrl;
  String? _resolvedPrimaryPhotoUrl;
  late final ChatTypingOutbound _typingOutbound;
  final AudioRecorder _voiceRecorder = AudioRecorder();
  String? _voiceRecordingPath;
  int _voiceRecordingDurationSeconds = 0;
  Timer? _voiceRecordingTimer;
  late final ChatPusherLifecycleNotifier _pusherLifecycle;
  late final ChatThreadMessagesNotifier _threadNotifier;
  late final ChatService _chatService;
  Timer? _realtimeFallbackKick;
  String? _lastSentText;
  DateTime? _lastSentAt;
  final ChatKeyboardAnchor _keyboardAnchor = ChatKeyboardAnchor();
  bool _jumpingToReply = false;
  Future<bool>? _loadMoreInFlight;

  @override
  void initState() {
    super.initState();
    _threadNotifier = ref.read(
      chatThreadMessagesProvider(widget.userId).notifier,
    );
    _chatService = ref.read(chatServiceProvider);
    _pusherLifecycle = ref.read(chatPusherLifecycleProvider.notifier);
    _typingOutbound = ChatTypingOutbound(send: _sendTypingIndicator);
    _scrollController.addListener(_onScroll);
    _resolvedUserName = widget.userName;
    _resolvedAvatarUrl = widget.avatarUrl;
    _loadCurrentUserId();
    if (widget.userId > 0) {
      _openUnreadCount = _peekUnreadCount();
      _showUnreadSeparator = _openUnreadCount > 0;
      _registerActivePeerImmediately();
      _resolvePeerDisplayIfNeeded();
      _bindLocalMessageStream();
      _loadMessages();
      _initializePusherListeners();
      _loadConversationMuteStatus();
      _seedInitialPeerPresence();
      _startRealtimeFallback();
    } else {
      _runAfterBuild(() {
        _thread.patch(
          isLoading: false,
          hasError: true,
          errorMessage: 'Invalid conversation. Please go back and try again.',
        );
      });
    }
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    _connectionSubscription?.cancel();
    _localMessagesSubscription?.cancel();
    _realtimeFallbackTimer?.cancel();
    _realtimeFallbackKick?.cancel();
    _typingOutbound.cancelTimers();
    _voiceRecordingTimer?.cancel();
    unawaited(_voiceRecorder.dispose());
    final chatService = _chatService;
    final conversationId = _conversationId;
    final peerId = widget.userId;
    _pusherLifecycle.scheduleCloseConversation(conversationId: conversationId);
    Future(() {
      unawaited(() async {
        try {
          if (conversationId != null && conversationId > 0) {
            await chatService.setConversationTyping(conversationId, false);
          } else {
            await chatService.setTypingStatus(peerId, false);
          }
        } catch (e) {
          AppLogger.warning(
            'Failed to clear typing indicator on dispose',
            tag: 'Chat',
            error: e,
          );
        }
      }());
    });
    _scrollController.dispose();
    final threadNotifier = _threadNotifier;
    Future<void>(() => threadNotifier.clear());
    super.dispose();
  }

  String get _peerDisplayName {
    final name = _resolvedUserName ?? widget.userName;
    if (name != null && name.trim().isNotEmpty && name.trim() != 'User') {
      return name.trim();
    }
    return 'User';
  }

  String? get _peerAvatarUrl => _resolvedAvatarUrl ?? widget.avatarUrl;

  String? get _peerCallPhotoUrl => _resolvedPrimaryPhotoUrl ?? _peerAvatarUrl;

  Future<void> _resolvePeerDisplayIfNeeded() async {
    try {
      final profile = await ref
          .read(profileServiceProvider)
          .getUserProfile(widget.userId);
      if (!mounted) return;
      final first = profile.firstName.trim();
      final primary = primaryProfileImage(profile.images);
      final avatar = primary?.avatarDisplayUrl ?? primary?.imageUrl;
      final photo = primaryProfilePhotoUrl(profile.images);
      setState(() {
        if (first.isNotEmpty) {
          _resolvedUserName = first;
        }
        if (avatar != null && avatar.isNotEmpty) {
          _resolvedAvatarUrl = avatar;
        }
        if (photo != null && photo.isNotEmpty) {
          _resolvedPrimaryPhotoUrl = photo;
        }
      });
      final resolvedAvatar = MediaUrl.resolve(avatar);
      ref
          .read(chatListPreviewProvider.notifier)
          .updatePeerAppearance(
            widget.userId,
            name: first.isNotEmpty ? first : null,
            avatarUrl: resolvedAvatar,
          );
      unawaited(
        ref
            .read(peerAvatarCacheProvider.notifier)
            .remember(widget.userId, resolvedAvatar),
      );
      unawaited(
        ref
            .read(chatLocalRepositoryProvider)
            .patchPeerAppearance(
              otherUserId: widget.userId,
              name: first.isNotEmpty ? first : null,
              primaryImageUrl: resolvedAvatar,
            ),
      );
    } catch (e) {
      AppLogger.warning(
        'Could not resolve chat peer display',
        tag: 'Chat',
        error: e,
      );
    }
  }

  void _openConversationInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatConversationInfoPage(
          userId: widget.userId,
          userName: _peerDisplayName,
          avatarUrl: _peerAvatarUrl,
          isOnline:
              ref.read(userPresenceCacheProvider)[widget.userId]?.isOnline ??
              false,
        ),
      ),
    );
  }

  /// Riverpod forbids provider writes during build/initState. Always wait
  /// until the current frame finishes so [action] cannot run mid-build.
  void _runAfterBuild(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final cached = ref.read(cachedCurrentUserProvider).valueOrNull;
      final userService = ref.read(userServiceProvider);
      if (cached != null && cached.id > 0) {
        _runAfterBuild(() => _applyCurrentUserId(cached.id));
        return;
      }

      final userInfo = await userService.getUserInfo();
      if (!mounted) return;
      _applyCurrentUserId(userInfo.id);
    } catch (e) {
      if (!mounted) return;
      AppLogger.warning(
        'Could not resolve current user for sent-status',
        tag: 'Chat',
        error: e,
      );
    }
  }

  void _applyCurrentUserId(int userId) {
    if (!mounted) return;
    _currentUserId = userId;
    _messages = _messages.map((msg) {
      final senderId = msg['sender_id'] as int?;
      if (senderId == null) return msg;
      return {...msg, 'is_sent': senderId == userId};
    }).toList();
    setState(() {});
  }

  Future<void> _loadConversationMuteStatus() async {
    try {
      final muted = await ref
          .read(chatServiceProvider)
          .isConversationMuted(widget.userId);
      if (!mounted) return;
      ref
          .read(conversationMuteCacheProvider.notifier)
          .setMuted(widget.userId, muted);
    } catch (e) {
      AppLogger.warning(
        'Conversation mute status load failed',
        tag: 'Chat',
        error: e,
      );
    }
  }

  void _initializePusherListeners() {
    final pusher = ref.read(pusherWebSocketServiceProvider);

    _connectionSubscription = pusher.connectionStream.listen((status) {
      if (!mounted) return;
      if (status == ConnectionStatus.connected) {
        unawaited(_pollRemoteMessages());
      }
    });

    _callEventSubscription = pusher.callEventStream.listen((event) {
      if (!mounted) return;
      if (event.name != 'call.ended' &&
          event.name != 'call.rejected' &&
          event.name != 'call.busy') {
        return;
      }
      unawaited(_handleCallTimelineEvent(event));
    });
  }

  void _seedInitialPeerPresence() {
    _runAfterBuild(() {
      final cached = ref.read(userPresenceCacheProvider)[widget.userId];
      if (cached != null) return;
      for (final item in ref.read(chatListPreviewProvider).items) {
        if (item.id != widget.userId) continue;
        ref
            .read(userPresenceCacheProvider.notifier)
            .apply(
              UserPresenceEvent(
                userId: widget.userId,
                isOnline: item.isOnline,
                lastSeenAt: item.lastSeenAt,
                timestamp: DateTime.now(),
              ),
            );
        break;
      }
    });
    unawaited(_refreshPeerPresenceFromProfile());
  }

  Future<void> _refreshPeerPresenceFromProfile() async {
    try {
      final profile = await ref
          .read(profileServiceProvider)
          .getUserProfile(widget.userId);
      if (!mounted) return;
      if (ref.read(userPresenceCacheProvider).containsKey(widget.userId)) {
        return;
      }
      ref
          .read(userPresenceCacheProvider.notifier)
          .apply(
            UserPresenceEvent(
              userId: widget.userId,
              isOnline: profile.isOnline == true,
              lastSeenAt: profile.lastSeen,
              timestamp: DateTime.now(),
            ),
          );
    } catch (e) {
      AppLogger.warning(
        'Could not refresh peer presence',
        tag: 'Chat',
        error: e,
      );
    }
  }

  void _startRealtimeFallback() {
    _realtimeFallbackTimer?.cancel();
    _realtimeFallbackKick?.cancel();
    _realtimeFallbackKick = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (ref.read(pusherWebSocketServiceProvider).isConnected) return;
      unawaited(_pollRemoteMessages());
    });
    _realtimeFallbackTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      if (ref.read(pusherWebSocketServiceProvider).isConnected) return;
      unawaited(_pollRemoteMessages());
    });
  }

  Future<void> _pollRemoteMessages() async {
    try {
      final lastId = ChatReconnectCatchUp.lastServerId(_messages);
      if (lastId == null) {
        final history = await ref
            .read(chatServiceProvider)
            .getChatHistory(
              receiverId: widget.userId,
              page: 1,
              limit: _historyPageSize,
            );
        if (!mounted) return;
        final added = _mergePolledHistory(history);
        if (added && _isNearBottom()) _scrollToBottom();
        return;
      }

      var afterId = lastId;
      var added = false;
      for (var page = 0; page < ChatReconnectCatchUp.maxPages; page++) {
        final history = await ref
            .read(chatServiceProvider)
            .getChatHistory(
              receiverId: widget.userId,
              afterId: afterId,
              limit: ChatReconnectCatchUp.pageSize,
            );
        if (!mounted) return;
        if (_mergePolledHistory(history)) added = true;
        final next = ChatReconnectCatchUp.nextAfterId(
          page: history,
          currentAfterId: afterId,
        );
        if (next == null) break;
        afterId = next;
      }
      if (added && _isNearBottom()) _scrollToBottom();
    } catch (e) {
      AppLogger.warning(
        'Chat realtime fallback poll failed',
        tag: 'Chat',
        error: e,
      );
    }
  }

  bool _mergePolledHistory(ChatHistoryResult history) {
    final conversationId =
        history.conversationId ??
        history.messages
            .map((m) => m.conversationId)
            .whereType<int>()
            .where((id) => id > 0)
            .firstOrNull;
    if (conversationId != null &&
        conversationId > 0 &&
        _conversationId != conversationId) {
      unawaited(_subscribePusherConversation(conversationId));
    }
    var added = false;
    // History is newest-first; ingest oldest-first then keep chronological order.
    for (final message in history.messages.reversed) {
      _enterGate.markIdentity(
        ChatMessageEnterGate.identity(
          clientId: message.clientId,
          id: message.id,
        ),
      );
      if (_ingestRemoteMessage(message, scroll: false)) {
        added = true;
      }
    }
    if (mounted) {
      _messages = ChatTimelineMerger.sortChronologically(_messages);
    }
    _ackIncomingDelivered(history.messages);
    return added;
  }

  bool _ingestRemoteMessage(Message message, {bool scroll = true}) {
    final result = ChatThreadRemoteIngest.apply(
      thread: _thread,
      message: message,
      peerUserId: widget.userId,
      currentUserId: _currentUserId,
    );
    if (result.updatedExistingServerRow) {
      if (message.senderId == widget.userId) {
        _ackIncomingDelivered([message]);
      }
      return false;
    }
    if (ChatUnseenIncoming.shouldIncrementBadge(
      insertedNewRow: result.insertedNew,
      fromPeer: message.senderId == widget.userId,
      nearBottom: _isNearBottom(),
    )) {
      ref
          .read(chatThreadViewportProvider(widget.userId).notifier)
          .incrementUnseen();
    }
    unawaited(
      ref
          .read(chatLocalRepositoryProvider)
          .upsertMessage(message, widget.userId),
    );
    if (scroll && _isNearBottom()) {
      _scrollToBottom(bounce: result.insertedNew);
    }
    if (result.insertedNew &&
        message.senderId == widget.userId &&
        _isNearBottom()) {
      unawaited(_markAsRead());
    }
    if (message.senderId == widget.userId) {
      _ackIncomingDelivered([message]);
    }
    return true;
  }

  bool _sameMessageId(dynamic rawId, int messageId) {
    return ChatOptimistic.sameMessageId(rawId, messageId);
  }

  Future<void> _handleCallTimelineEvent(CallSignalingEvent event) async {
    final fromPayload = ChatCallTimeline.fromSignalingPayload(event.payload);
    if (fromPayload != null &&
        ChatCallTimeline.involvesThread(
          call: fromPayload,
          peerUserId: widget.userId,
          currentUserId: _currentUserId,
        )) {
      _appendCallEntry(fromPayload);
    }

    final callId = event.payload['call_id']?.toString();
    if (callId == null || callId.isEmpty) return;

    try {
      final call = await ref.read(callServiceProvider).getCall(callId);
      if (!ChatCallTimeline.involvesThread(
            call: call,
            peerUserId: widget.userId,
            currentUserId: _currentUserId,
          ) ||
          !CallLogLabels.isTerminalStatus(call.status.toLowerCase())) {
        return;
      }
      _appendCallEntry(call);
    } catch (e) {
      AppLogger.warning('Call timeline hydrate failed', tag: 'Chat', error: e);
    }
  }

  void _appendCallEntry(Call call) {
    if (!CallLogLabels.isTerminalStatus(call.status.toLowerCase())) {
      return;
    }

    _messages = ChatCallTimeline.upsert(_messages, _callToMap(call));
    unawaited(
      ref
          .read(callHistoryLocalCacheProvider.notifier)
          .upsertCall(widget.userId, call),
    );
    _scrollToBottom();
  }

  Future<void> _subscribePusherConversation(int conversationId) async {
    _conversationId = conversationId;
    await _pusherLifecycle.openConversation(
      conversationId: conversationId,
      otherUserId: widget.userId,
    );
  }

  int _peekUnreadCount() {
    return ChatUnreadSeparator.unreadCountOfPeer(
      peerUserId: widget.userId,
      items: [
        for (final item in ref.read(chatListPreviewProvider).items)
          (id: item.id, unreadCount: item.unreadCount),
      ],
    );
  }

  /// FCM must treat this peer as "open" before history (or a conversation id) exists.
  void _registerActivePeerImmediately() {
    ActiveChatPeerBridge.primeActivePeer(widget.userId);
    _runAfterBuild(() {
      ref
          .read(chatListPreviewProvider.notifier)
          .clearUnreadForPeer(widget.userId);
      unawaited(
        Future<void>(() async {
          if (!mounted) return;
          _pusherLifecycle.markActiveChat(peerUserId: widget.userId);
          await _subscribeWhenConversationKnown();
        }),
      );
    });
  }

  Future<void> _subscribeWhenConversationKnown() async {
    if (_conversationId != null && _conversationId! > 0) return;

    final fromList = ref
        .read(chatListPreviewProvider)
        .items
        .where((item) => item.id == widget.userId && item.chatId > 0)
        .map((item) => item.chatId)
        .where((id) => id != widget.userId)
        .firstOrNull;
    if (fromList != null) {
      await _subscribePusherConversation(fromList);
      return;
    }

    try {
      final localId = await ref
          .read(chatLocalRepositoryProvider)
          .conversationIdForOtherUser(widget.userId);
      if (!mounted) return;
      if (localId != null &&
          localId > 0 &&
          (_conversationId == null || _conversationId != localId)) {
        await _subscribePusherConversation(localId);
      }
    } catch (e) {
      AppLogger.warning(
        'Local conversation id lookup failed',
        tag: 'Chat',
        error: e,
      );
    }
  }

  void _onTypingChanged(String text) {
    _typingOutbound.onTextChanged(text);
  }

  void _onComposerFocusChange(bool hasFocus) {
    if (!hasFocus) {
      _typingOutbound.onFocusLost();
    }
  }

  Future<void> _sendTypingIndicator(bool isTyping) async {
    try {
      final conversationId = _conversationId;
      if (conversationId != null && conversationId > 0) {
        await ref
            .read(chatServiceProvider)
            .setConversationTyping(conversationId, isTyping);
      } else {
        await ref
            .read(chatServiceProvider)
            .setTypingStatus(widget.userId, isTyping);
      }
    } catch (e) {
      AppLogger.warning(
        'Typing indicator failed (non-blocking)',
        tag: 'Chat',
        error: e,
      );
    }
  }

  void _onScroll() {
    _updateJumpToBottomVisibility();
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        _loadMoreFailed ||
        !_hasMoreMessages) {
      return;
    }
    if (ChatThreadScroll.isNearOldest(
      pixels: _scrollController.position.pixels,
      maxScrollExtent: _scrollController.position.maxScrollExtent,
    )) {
      unawaited(_loadMoreMessages());
    }
  }

  void _updateJumpToBottomVisibility() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final showFab = ChatUnseenIncoming.shouldShowFab(pixels: pos.pixels);
    ref
        .read(chatThreadViewportProvider(widget.userId).notifier)
        .applyScroll(
          showFab: showFab,
          atBottom: ChatUnseenIncoming.isNearBottom(pixels: pos.pixels),
        );
  }

  void _onChatKeyboardInset(double bottom) {
    if (_keyboardAnchor.shouldPinToBottom(
      insetBottom: bottom,
      nearBottom: _isNearBottom(),
    )) {
      _pinThreadToKeyboard();
    }
  }

  void _onChatKeyboardInsetTick() {
    if (_keyboardAnchor.isPinned) {
      _pinThreadToKeyboard();
    }
  }

  void _onChatKeyboardInsetSettled() {
    if (_keyboardAnchor.isPinned) {
      _pinThreadToKeyboard();
    }
  }

  void _pinThreadToKeyboard() {
    if (!_scrollController.hasClients || !mounted) return;
    final pos = _scrollController.position;
    if (!pos.hasContentDimensions) return;
    final target = ChatKeyboardAnchor.pinnedExtent(pixels: pos.pixels);
    if (target == null) return;
    _scrollController.jumpTo(target);
  }

  void _jumpToLatest() {
    ref.read(chatThreadViewportProvider(widget.userId).notifier).clearUnseen();
    if (_showUnreadSeparator) {
      setState(() => _showUnreadSeparator = false);
    }
    _scrollToBottom();
    unawaited(_markAsRead());
  }

  Future<void> _jumpToRepliedMessage(Map<String, dynamic> message) async {
    final targetId = ChatReplyJump.replyToId(message);
    if (targetId == null || _jumpingToReply) return;
    _jumpingToReply = true;
    var showedSearching = false;
    try {
      var jumped = await _tryJumpToRepliedMessage(targetId);
      if (jumped || !mounted) return;

      showedSearching = true;
      _showReplyJumpSnack(
        ChatReplyJump.searchingMessage,
        duration: const Duration(seconds: 30),
      );

      var pages = 0;
      var emptyPage = false;
      while (mounted &&
          ChatReplyJump.shouldKeepPaginating(
            found: _replyTargetInThread(targetId),
            hasMore: _hasMoreMessages,
            loadFailed: _loadMoreFailed,
            pagesLoaded: pages,
            emptyPage: emptyPage,
          )) {
        pages++;
        final added = await _loadMoreMessages();
        if (!mounted) return;
        emptyPage = !added;
        if (_replyTargetInThread(targetId)) break;
      }

      if (!mounted) return;
      if (showedSearching) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      jumped = await _tryJumpToRepliedMessage(targetId);
      if (jumped || !mounted) return;

      AppLogger.warning(
        'Original message $targetId not in loaded history',
        tag: 'Chat',
      );
      _showReplyJumpSnack(ChatReplyJump.notLoadedMessage);
    } finally {
      _jumpingToReply = false;
    }
  }

  bool _replyTargetInThread(int targetId) {
    _thread.ensureIndex();
    return _thread.index.byServerId(targetId) != null;
  }

  void _flashReplyHighlight(int messageId) {
    if (!mounted || messageId <= 0) return;
    ref
        .read(chatReplyHighlightProvider(widget.userId).notifier)
        .flash(messageId, hold: AppAnimations.chatReplyHighlightHold);
  }

  void _showReplyJumpSnack(String text, {Duration? duration}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _tryJumpToRepliedMessage(int targetId) async {
    if (!mounted) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    var jumped = await ChatReplyJump.ensureVisible(targetId, context: context);
    if (jumped) {
      _flashReplyHighlight(targetId);
      return true;
    }
    if (!mounted) return false;

    _thread.ensureIndex();
    final chrono = _thread.index.byServerId(targetId);
    if (chrono == null) return false;

    if (_scrollController.hasClients) {
      final row = _messages[chrono];
      final decorated = ChatUnreadSeparator.insert(
        items: ChatDateBadgeInserter.wrap(_messages),
        unreadCount: _showUnreadSeparator ? _openUnreadCount : 0,
      );
      final slots = ChatTimelineSlots.build(decoratedRows: decorated);
      final pixels = ChatReplyJump.estimatedPixels(
        slots: slots,
        rowKey: ChatTimelineSlots.rowKey(row, fallbackIndex: chrono),
        maxScrollExtent: _scrollController.position.maxScrollExtent,
      );
      if (pixels != null) {
        final duration = AppAnimations.chatJumpToReplyDuration(context);
        if (duration == Duration.zero) {
          _scrollController.jumpTo(pixels);
        } else {
          await _scrollController.animateTo(
            pixels,
            duration: duration,
            curve: AppAnimations.curveDefault,
          );
        }
        if (!mounted) return false;
        await ChatReplyJump.ensureVisible(targetId, context: context);
      }
    }
    _flashReplyHighlight(targetId);
    return true;
  }

  void _bindLocalMessageStream() {
    _localMessagesSubscription?.cancel();
    _localMessagesSubscription = ref
        .read(chatLocalRepositoryProvider)
        .watchAllMessagesForOtherUser(widget.userId)
        .listen(
          _onLocalMessages,
          onError: (Object error) {
            AppLogger.warning(
              'Local chat message stream failed',
              tag: 'Chat',
              error: error,
            );
          },
        );
  }

  void _onLocalMessages(List<Message> messages) {
    if (!mounted) return;
    final next = ChatThreadLocalApply.combine(
      messages: messages,
      peerUserId: widget.userId,
      currentUserId: _currentUserId,
      callRows: _cachedCallMaps(),
      previousRows: _messages,
      replyPreview: _replyPreviewForId,
    );
    _thread.setRows(next);
  }

  Future<void> _loadMessages({bool forceRefresh = false}) async {
    if (widget.userId <= 0) {
      if (mounted) {
        _thread.patch(
          isLoading: false,
          hasError: true,
          errorMessage: 'Invalid conversation. Please go back and try again.',
        );
      }
      return;
    }

    final localRepo = ref.read(chatLocalRepositoryProvider);
    var showedCache = false;
    try {
      final cached = await localRepo.getAllMessagesForOtherUser(widget.userId);
      final pagination = await localRepo.loadHistoryPagination(widget.userId);
      final cachedCallMaps = _cachedCallMaps();
      if ((cached.isNotEmpty || cachedCallMaps.isNotEmpty) && mounted) {
        showedCache = true;
        final mergedCache = await _mergeQueuedOutbox(
          ChatTimelineMerger.merge(
            messages: cached.map(_messageToMap).toList(),
            calls: cachedCallMaps,
          ),
        );
        _enterGate.markAll(mergedCache);
        _thread.patch(
          rows: mergedCache,
          isLoading: false,
          hasError: false,
          clearErrorMessage: true,
        );
        _hasMoreMessages =
            pagination?.hasMore ?? cached.length >= _historyPageSize;
        _nextCursor = pagination?.nextCursor;
        _scrollAfterHistoryPaint();
        unawaited(_cacheVisualMedia(cached));
        unawaited(
          ref
              .read(callHistoryLocalCacheProvider.notifier)
              .saveForPeer(widget.userId, _cachedPeerCalls()),
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to load cached chat messages',
        tag: 'Chat',
        error: e,
      );
    }
    await _mergeOutboxIntoThread();

    _thread.patch(
      isLoading: !showedCache,
      hasError: false,
      clearErrorMessage: true,
    );
    if (forceRefresh) {
      _hasMoreMessages = true;
      _nextCursor = null;
    }

    try {
      final chatService = ref.read(chatServiceProvider);
      final historyFuture = chatService.getChatHistory(
        receiverId: widget.userId,
        page: 1,
        limit: _historyPageSize,
        forceRefresh: forceRefresh,
      );
      final callsFuture = ref
          .read(getCallHistoryUseCaseProvider)
          .execute(peerUserId: widget.userId, limit: 50);

      final history = await historyFuture;
      _ackIncomingDelivered(history.messages);
      List<Call> calls = const [];
      try {
        calls = await callsFuture;
      } catch (e) {
        AppLogger.warning(
          'Call history fetch failed; using local cache',
          tag: 'Chat',
          error: e,
        );
        calls = ref
            .read(callHistoryLocalCacheProvider.notifier)
            .callsForPeer(widget.userId);
      }

      if (mounted) {
        final messageMaps = history.messages
            .map((message) => _messageToMap(message))
            .toList();
        final callMaps = calls
            .where((call) => CallLogLabels.isTerminalStatus(call.status))
            .map(_callToMap)
            .toList();

        final merged = await _mergeQueuedOutbox(
          ChatTimelineMerger.withInFlightOptimistic(
            serverTimeline: ChatTimelineMerger.merge(
              messages: messageMaps,
              calls: callMaps,
            ),
            previous: _messages,
          ),
        );

        _enterGate.markAll(merged);
        _thread.patch(
          rows: merged,
          isLoading: false,
          isLoadingMore: false,
          loadMoreFailed: false,
        );
        _hasMoreMessages = history.hasMore;
        _nextCursor = history.nextCursor;
        _scrollAfterHistoryPaint();
        unawaited(localRepo.upsertMessages(history.messages, widget.userId));
        unawaited(
          ref
              .read(callHistoryLocalCacheProvider.notifier)
              .saveForPeer(widget.userId, calls),
        );
        unawaited(_cacheVisualMedia(history.messages));
        unawaited(
          localRepo.saveHistoryPagination(
            widget.userId,
            ChatHistoryPaginationMeta(
              hasMore: history.hasMore,
              nextCursor: history.nextCursor,
            ),
          ),
        );
        await _mergeOutboxIntoThread();

        final conversationId =
            history.conversationId ??
            history.messages
                .map((m) => m.conversationId)
                .whereType<int>()
                .where((id) => id > 0)
                .firstOrNull;
        if (conversationId != null && conversationId > 0) {
          await _subscribePusherConversation(conversationId);
        }

        await _markAsRead();
      }
    } on ApiError catch (e) {
      AppLogger.warning('Chat history refresh failed', tag: 'Chat', error: e);
      if (mounted && !showedCache) {
        _thread.patch(
          hasError: true,
          errorMessage: e.message,
          isLoading: false,
        );
      }
    } catch (e) {
      AppLogger.warning('Chat history refresh failed', tag: 'Chat', error: e);
      if (mounted && !showedCache) {
        _thread.patch(
          hasError: true,
          errorMessage: e.toString(),
          isLoading: false,
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _mergeQueuedOutbox(
    List<Map<String, dynamic>> timeline,
  ) async {
    final pending = await ref
        .read(chatOutboundQueueServiceProvider)
        .getPending();
    if (!mounted) return timeline;
    ref.read(chatOutboxUiProvider.notifier).sync(pending);
    final extra = ChatOutboxUi.rowsForPeer(pending, widget.userId);
    if (extra.isEmpty) return timeline;
    return ChatTimelineMerger.withInFlightOptimistic(
      serverTimeline: timeline,
      previous: extra,
    );
  }

  Future<void> _mergeOutboxIntoThread() async {
    if (!mounted) return;
    final merged = await _mergeQueuedOutbox(_messages);
    if (!mounted) return;
    _thread.setRows(merged);
  }

  DateTime? _oldestMessageCreatedAt() {
    DateTime? oldest;
    for (final item in _messages) {
      if (item['kind'] == 'call') continue;
      final ts = item['timestamp'];
      if (ts is! DateTime) continue;
      if (oldest == null || ts.isBefore(oldest)) {
        oldest = ts;
      }
    }
    return oldest;
  }

  Future<bool> _loadMoreFromCache() async {
    final oldest = _oldestMessageCreatedAt();
    if (oldest == null) return false;

    final localRepo = ref.read(chatLocalRepositoryProvider);
    final older = await localRepo.getOlderMessagesForOtherUser(
      widget.userId,
      beforeCreatedAt: oldest,
      limit: _historyPageSize,
    );
    if (older.isEmpty || !mounted) return false;

    final existingMessageIds = _messages
        .where((item) => item['kind'] != 'call')
        .map((item) => item['id'])
        .whereType<int>()
        .toSet();

    final newMessageMaps = ChatLoadOlder.withoutExistingIds(
      incoming: older,
      idOf: (message) => message.id,
      existingIds: existingMessageIds,
    ).map(_messageToMap).toList();
    if (newMessageMaps.isEmpty) return false;

    final existingMessages = _messages
        .where((item) => item['kind'] != 'call')
        .toList();
    final callItems = _messages
        .where((item) => item['kind'] == 'call')
        .toList();

    _enterGate.markAll(newMessageMaps);
    _messages = ChatTimelineMerger.merge(
      messages: [...newMessageMaps, ...existingMessages],
      calls: callItems,
    );

    // Reverse list is anchored at pixel 0 (latest). Older rows grow
    // maxScrollExtent â€” no jumpTo compensation (ChatLoadOlder).
    return true;
  }

  Future<bool> _loadMoreMessages() {
    return _loadMoreInFlight ??= _loadMoreMessagesBody().whenComplete(() {
      _loadMoreInFlight = null;
    });
  }

  Future<bool> _loadMoreMessagesBody() async {
    if (_isLoading || !_hasMoreMessages) return false;

    _thread.patch(isLoadingMore: true, loadMoreFailed: false);

    try {
      final loadedFromCache = await _loadMoreFromCache();
      if (loadedFromCache) {
        if (mounted) _thread.patch(isLoadingMore: false);
        return true;
      }
    } catch (e) {
      AppLogger.warning(
        'load more from cache failed; falling through to network',
        tag: 'Chat',
        error: e,
      );
    }

    final cursor = _nextCursor;
    if (cursor == null) {
      if (mounted) {
        _thread.patch(isLoadingMore: false);
        _hasMoreMessages = false;
      }
      return false;
    }

    try {
      final chatService = ref.read(chatServiceProvider);
      final localRepo = ref.read(chatLocalRepositoryProvider);
      final history = await chatService.getChatHistory(
        receiverId: widget.userId,
        limit: _historyPageSize,
        beforeId: cursor.beforeId,
        beforeCreatedAt: cursor.beforeCreatedAt,
      );

      if (!mounted) return false;

      final existingMessageIds = _messages
          .where((item) => item['kind'] != 'call')
          .map((item) => item['id'])
          .whereType<int>()
          .toSet();

      final newMessageMaps = ChatLoadOlder.withoutExistingIds(
        incoming: history.messages,
        idOf: (message) => message.id,
        existingIds: existingMessageIds,
      ).map((message) => _messageToMap(message)).toList();

      if (newMessageMaps.isEmpty) {
        _thread.patch(isLoadingMore: false);
        _hasMoreMessages = history.hasMore;
        _nextCursor = history.nextCursor;
        unawaited(
          localRepo.saveHistoryPagination(
            widget.userId,
            ChatHistoryPaginationMeta(
              hasMore: history.hasMore,
              nextCursor: history.nextCursor,
            ),
          ),
        );
        return false;
      }

      final existingMessages = _messages
          .where((item) => item['kind'] != 'call')
          .toList();
      final callItems = _messages
          .where((item) => item['kind'] == 'call')
          .toList();

      _enterGate.markAll(newMessageMaps);
      _messages = ChatTimelineMerger.merge(
        messages: [...newMessageMaps, ...existingMessages],
        calls: callItems,
      );
      _thread.patch(isLoadingMore: false);
      _hasMoreMessages = history.hasMore;
      _nextCursor = history.nextCursor;

      unawaited(localRepo.upsertMessages(history.messages, widget.userId));
      unawaited(_cacheVisualMedia(history.messages));
      unawaited(
        localRepo.saveHistoryPagination(
          widget.userId,
          ChatHistoryPaginationMeta(
            hasMore: history.hasMore,
            nextCursor: history.nextCursor,
          ),
        ),
      );
      return true;
    } catch (e) {
      AppLogger.warning('load more messages failed', tag: 'Chat', error: e);
      if (mounted) {
        _thread.patch(isLoadingMore: false, loadMoreFailed: true);
      }
      return false;
    }
  }

  Map<String, dynamic> _callToMap(Call call) {
    return {
      'kind': 'call',
      'call_id': call.id,
      'caller_id': call.callerId,
      'receiver_id': call.receiverId,
      'call_type': call.callType,
      'status': call.status,
      'duration_seconds': call.duration?.inSeconds ?? 0,
      'timestamp': call.timelineTimestamp,
      'call': call,
    };
  }

  List<Call> _cachedPeerCalls() {
    final seen = <int>{};
    final calls = <Call>[
      ...ref
          .read(callHistoryLocalCacheProvider.notifier)
          .callsForPeer(widget.userId),
      ...ref
          .read(messengerCallsProvider)
          .calls
          .where(
            (call) =>
                call.callerId == widget.userId ||
                call.receiverId == widget.userId,
          ),
    ];
    final unique = <Call>[];
    for (final call in calls) {
      if (!CallLogLabels.isTerminalStatus(call.status)) continue;
      if (call.id <= 0 || !seen.add(call.id)) continue;
      unique.add(call);
    }
    return unique;
  }

  List<Map<String, dynamic>> _cachedCallMaps() =>
      _cachedPeerCalls().map(_callToMap).toList();

  Future<void> _redialCall(Call call) async {
    final confirmed = await showCallRedialConfirmSheet(
      context: context,
      peerName: _peerDisplayName,
      isVideo: call.isVideoCall,
    );
    if (!confirmed || !mounted) return;
    if (call.isVideoCall && !await _ensureVideoCallAccess()) return;
    if (!mounted) return;
    await startOutgoingCall(
      context: context,
      ref: ref,
      recipientId: widget.userId,
      recipientName: _peerDisplayName,
      recipientAvatarUrl: _peerCallPhotoUrl,
      type: call.isVideoCall ? OutgoingCallType.video : OutgoingCallType.voice,
    );
  }

  Map<String, dynamic> _messageToMap(Message message) {
    return ChatThreadRowMap.fromMessage(
      message,
      peerUserId: widget.userId,
      currentUserId: _currentUserId,
      replyPreview: _replyPreviewForId,
    );
  }

  String? _replyPreviewForId(int? id) {
    if (id == null || id <= 0) return null;
    for (final msg in _messages) {
      if (_sameMessageId(msg['id'], id)) {
        final text = msg['text']?.toString() ?? '';
        if (text.isNotEmpty) return text;
        final type = msg['type']?.toString() ?? 'text';
        if (type == 'image') return 'Photo';
        if (type == 'voice') return 'Voice message';
        if (type == 'video') return 'Video';
      }
    }
    return null;
  }

  Map<String, dynamic> _optimisticVoiceMap({
    required String clientId,
    required int durationSeconds,
    String? localPath,
  }) {
    return {
      'id': 0,
      'client_id': clientId,
      'text': '',
      'is_sent': true,
      'sender_id': _currentUserId,
      'timestamp': DateTime.now(),
      'is_read': false,
      'is_delivered': false,
      'type': 'voice',
      'media_duration': durationSeconds,
      'local_path': localPath,
      'delivery_status': MessageDeliveryStatus.sending,
    };
  }

  Map<String, dynamic> _optimisticMap({
    required String clientId,
    required String text,
    String type = 'text',
    String? attachmentUrl,
    String? localPath,
    int? expiresInSeconds,
    int? replyToMessageId,
    String? replyToText,
    String? replyToName,
    String? placeholderDataUri,
    int? mediaWidth,
    int? mediaHeight,
  }) {
    return {
      'id': 0,
      'client_id': clientId,
      'text': text,
      'is_sent': true,
      'sender_id': _currentUserId,
      'timestamp': DateTime.now(),
      'is_read': false,
      'is_delivered': false,
      'type': type,
      'attachment_url': attachmentUrl,
      'local_path': localPath ?? attachmentUrl,
      'expires_in_seconds': expiresInSeconds,
      'reply_to_message_id': replyToMessageId,
      'reply_to_text': replyToText,
      'reply_to_name': replyToName,
      'placeholder_data_uri': placeholderDataUri,
      'media_width': mediaWidth,
      'media_height': mediaHeight,
      'delivery_status': MessageDeliveryStatus.sending,
      'hero_tag': ChatGalleryItem.heroTagFor(clientId: clientId),
    };
  }

  void _markMessageFailed(String clientId) {
    _thread.mapRows((msg) {
      if (msg['client_id'] == clientId) {
        return ChatSendRetry.markFailed(msg);
      }
      return msg;
    });
  }

  void _reportImageUploadProgress(String clientId, int sent, int total) {
    final progress = total <= 0 ? 0.0 : sent / total;
    ref
        .read(chatImageUploadProgressProvider.notifier)
        .setProgress(clientId, progress);
  }

  void Function(int, int)? _imageSendProgressCallback(
    String? clientId,
    String type,
  ) {
    if (type != 'image' || clientId == null || clientId.isEmpty) return null;
    return (sent, total) => _reportImageUploadProgress(clientId, sent, total);
  }

  void _completeImageUploadProgress(String? clientId, String type) {
    if (type != 'image' || clientId == null || clientId.isEmpty) return;
    ref.read(chatImageUploadProgressProvider.notifier).setProgress(clientId, 1);
  }

  Map<String, dynamic> _carryLocalImagePlaceholder(
    String clientId,
    Map<String, dynamic> serverMap,
  ) {
    for (final row in _messages) {
      if (row['client_id']?.toString() != clientId) continue;
      return {
        ...serverMap,
        'placeholder_data_uri':
            serverMap['placeholder_data_uri'] ?? row['placeholder_data_uri'],
        'media_width': serverMap['media_width'] ?? row['media_width'],
        'media_height': serverMap['media_height'] ?? row['media_height'],
      };
    }
    return serverMap;
  }

  void _replaceOptimisticMessage(String clientId, Message serverMessage) {
    _messages = ChatTimelineMerger.sortChronologically(
      ChatOptimistic.replaceWithServer(
        messages: _messages,
        clientId: clientId,
        serverId: serverMessage.id,
        serverMap: _carryLocalImagePlaceholder(
          clientId,
          _messageToMap(
            serverMessage.clientId == null || serverMessage.clientId!.isEmpty
                ? serverMessage.copyWith(clientId: clientId)
                : serverMessage,
          ),
        ),
      ),
    );
    unawaited(
      ref
          .read(chatLocalRepositoryProvider)
          .upsertMessage(serverMessage, widget.userId),
    );
    final conversationId = serverMessage.conversationId;
    if (conversationId != null && conversationId > 0) {
      unawaited(_subscribePusherConversation(conversationId));
    }
  }

  Future<void> _onVoiceListened(Map<String, dynamic> message) async {
    if (message['is_sent'] == true) return;
    await _markAsRead();
  }

  Future<void> _markAsRead() async {
    _runAfterBuild(() {
      ref
          .read(chatListPreviewProvider.notifier)
          .clearUnreadForPeer(widget.userId);
    });
    try {
      final chatService = ref.read(chatServiceProvider);
      final conversationId = _conversationId;
      if (conversationId != null && conversationId > 0) {
        await chatService.markConversationAsRead(conversationId);
      } else {
        await chatService.markAsRead(widget.userId);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to mark messages as read',
        tag: 'Chat',
        error: e,
      );
    }
  }

  Future<void> _onPinnedBannerTap() async {
    final pinned = ref.read(chatPinnedBannerProvider(widget.userId));
    final messageId = pinned.messageId;
    if (messageId != null && messageId > 0) {
      await _jumpToRepliedMessage({'reply_to_message_id': messageId});
      return;
    }
    await _showPinnedMessages();
  }

  Future<void> _togglePin(Map<String, dynamic> message) async {
    final messageId = message['id'] is int
        ? message['id'] as int
        : int.tryParse(message['id']?.toString() ?? '') ?? 0;
    if (messageId <= 0) return;
    final banner = ref.read(chatPinnedBannerProvider(widget.userId).notifier);
    final snapshot = ref.read(chatPinnedBannerProvider(widget.userId));
    final preview = chatMessagePreviewText(
      message: message['text']?.toString(),
      messageType: message['type']?.toString(),
    );
    try {
      if (snapshot.isPinned(messageId)) {
        await _chatService.unpinMessage(messageId);
        if (!mounted) return;
        banner.applyUnpinned(messageId);
      } else {
        final previousId = snapshot.messageId;
        if (previousId != null && previousId != messageId) {
          try {
            await _chatService.unpinMessage(previousId);
          } catch (e) {
            AppLogger.warning(
              'unpin previous $previousId failed',
              tag: 'Chat',
              error: e,
            );
          }
        }
        await _chatService.pinMessage(messageId);
        if (!mounted) return;
        banner.applyPinned(messageId: messageId, preview: preview);
      }
      ref.invalidate(pinnedCountProvider(widget.userId));
    } catch (e) {
      AppLogger.warning('toggle pin $messageId failed', tag: 'Chat', error: e);
      if (!mounted) return;
      ErrorHandlerService.handleError(context, e);
    }
  }

  Future<void> _showPinnedMessages() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final pinned = await chatService.getPinnedMessages(widget.userId);
      if (!mounted) return;
      if (pinned.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pinned messages found.')),
        );
        return;
      }
      AppActionBottomSheet.show<void>(
        context: context,
        showCancel: true,
        body: AppBottomSheetListBody(
          title: 'Pinned messages',
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: pinned.length,
            separatorBuilder: (_, __) => const AppBottomSheetDivider(),
            itemBuilder: (context, index) {
              final msg = pinned[index];
              return ListTile(
                title: AppText(msg.message, maxLines: 2),
                subtitle: AppText(
                  msg.createdAt.toLocal().toString(),
                  maxLines: 1,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(
                    _jumpToRepliedMessage({'reply_to_message_id': msg.id}),
                  );
                },
              );
            },
          ),
        ),
      );
    } catch (e) {
      AppLogger.warning('load pinned messages failed', tag: 'Chat', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load pinned messages.')),
      );
    }
  }

  bool _isNearBottom({double? threshold}) {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return ChatUnseenIncoming.isNearBottom(
      pixels: pos.pixels,
      threshold: threshold ?? ChatUnseenIncoming.autoScrollThreshold,
    );
  }

  void _scrollToBottom({bool bounce = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || !mounted) return;
      const target = ChatThreadScroll.latestPixels;
      final animate = AppAnimations.animationsEnabled(context);
      if (!animate) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: AppAnimations.chatJumpToBottomScroll,
        curve: Curves.easeOut,
      );
      if (bounce &&
          ChatArrivalBounce.shouldPlay(
            nearBottom: _isNearBottom(),
            animationsEnabled: animate,
          )) {
        ref.read(chatArrivalBounceProvider(widget.userId).notifier).play();
      }
    });
  }

  void _scrollAfterHistoryPaint() {
    if (_showUnreadSeparator) {
      unawaited(_scrollToUnreadSeparator());
      return;
    }
    _scrollToBottom();
  }

  Future<void> _scrollToUnreadSeparator() async {
    if (!mounted) return;
    final duration = AppAnimations.animationsEnabled(context)
        ? AppAnimations.chatJumpToBottomScroll
        : Duration.zero;
    final found = await ChatUnreadSeparatorScroll.reveal(
      separatorKey: _unreadSeparatorKey,
      controller: _scrollController,
      duration: duration,
    );
    if (!found && mounted) _scrollToBottom();
  }

  Future<void> _cacheVisualMedia(List<Message> messages) async {
    if (widget.userId <= 0 || messages.isEmpty) return;
    unawaited(ChatVisualMedia.prefetchMessages(messages));
    await ref
        .read(chatInfoCacheProvider.notifier)
        .mergeMedia(
          widget.userId,
          ChatVisualMedia.sharedFromMessages(messages),
        );
  }

  Future<void> _handleSend(String text, {String? existingClientId}) async {
    if (text.trim().isEmpty) return;

    final trimmed = text.trim();
    if (_editingMessageId != null && existingClientId == null) {
      await _submitEdit(trimmed);
      return;
    }
    if (existingClientId == null) {
      final now = DateTime.now();
      if (_lastSentText == trimmed &&
          _lastSentAt != null &&
          now.difference(_lastSentAt!) < const Duration(milliseconds: 800)) {
        return;
      }
      _lastSentText = trimmed;
      _lastSentAt = now;
    }

    final clientId = existingClientId ?? ChatClientIds.next();
    final replyId = existingClientId == null ? _repliedToMessageId : null;
    final replyText = existingClientId == null ? _repliedToMessage : null;
    final replyName = existingClientId == null ? _repliedToName : null;

    if (existingClientId == null) {
      _messages = [
        ..._messages,
        _optimisticMap(
          clientId: clientId,
          text: text,
          replyToMessageId: replyId,
          replyToText: replyText,
          replyToName: replyName,
        ),
      ];
      _composer.clear();
      ref
          .read(chatListPreviewProvider.notifier)
          .bumpOutgoingMessage(
            peerUserId: widget.userId,
            previewText: trimmed,
            lastMessageType: 'text',
            timestamp: DateTime.now(),
          );
    } else {
      _thread.mapRows((msg) {
        if (msg['client_id'] == clientId) {
          return {...msg, 'delivery_status': MessageDeliveryStatus.sending};
        }
        return msg;
      });
    }
    _scrollToBottom(bounce: true);

    try {
      final sentMessage = await ref
          .read(chatServiceProvider)
          .sendMessage(
            widget.userId,
            text,
            messageType: 'text',
            replyToMessageId: replyId,
            clientId: clientId,
          );

      if (mounted) {
        _replaceOptimisticMessage(clientId, sentMessage);
        ref
            .read(chatListPreviewProvider.notifier)
            .bumpOutgoingMessage(
              peerUserId: widget.userId,
              previewText: trimmed,
              lastMessageType: 'text',
              timestamp: sentMessage.createdAt,
              lastMessageId: sentMessage.id,
            );
        _scrollToBottom();
      }
    } on ApiError catch (e) {
      AppLogger.warning('Send text failed', tag: 'Chat', error: e);
      if (mounted) {
        if (e.upgradeRequired ||
            e.errorCode == 'CHAT_DAILY_SEND_LIMIT_REACHED') {
          await ChatUpgradeBottomSheet.show(context);
        } else if (!_isOfflineSendError(e)) {
          ErrorHandlerService.showErrorSnackBar(
            context,
            e,
            onRetry: () => _handleSend(text, existingClientId: clientId),
          );
        }
      }
    } catch (e) {
      AppLogger.warning('Send text failed', tag: 'Chat', error: e);
      if (mounted) {
        await _queueOrFailText(clientId: clientId, text: trimmed, error: e);
        if (!_isOfflineSendError(e)) {
          ErrorHandlerService.handleError(
            context,
            e,
            customMessage: 'Failed to send message',
            onRetry: () => _handleSend(text, existingClientId: clientId),
          );
        }
      }
    }
  }

  bool _isOfflineSendError(Object error) {
    if (error is ApiError) {
      if (error.code == 0) return true;
      final message = error.message.toLowerCase();
      return message.contains('internet') ||
          message.contains('connection') ||
          message.contains('queued');
    }
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('connection') ||
        text.contains('network');
  }

  Future<void> _queueOrFailText({
    required String clientId,
    required String text,
    required Object error,
  }) async {
    final senderId = _currentUserId ?? 0;
    if (_isOfflineSendError(error) && senderId > 0) {
      final queuedAt = DateTime.now();
      final queued = QueuedChatMessage(
        clientId: clientId,
        receiverId: widget.userId,
        senderId: senderId,
        message: text,
        createdAt: queuedAt,
      );
      await ref.read(chatOutboundQueueServiceProvider).enqueue(queued);
      unawaited(
        ref
            .read(chatLocalRepositoryProvider)
            .upsertMessage(
              Message(
                id: 0,
                senderId: senderId,
                receiverId: widget.userId,
                message: text,
                createdAt: queuedAt,
                clientId: clientId,
                deliveryStatus: MessageDeliveryStatus.queued,
              ),
              widget.userId,
            ),
      );
      ref.read(chatOutboxUiProvider.notifier).addReceiver(widget.userId);
      _thread.mapRows(
        (msg) => ChatOutboxUi.markStatus(
          msg,
          clientId,
          MessageDeliveryStatus.queued,
        ),
      );
      return;
    }
    _markMessageFailed(clientId);
  }

  void _beginReply(Map<String, dynamic> message) {
    if (message['kind'] == 'call') return;
    final id = message['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
    if (parsedId <= 0) return;
    final type = message['type']?.toString() ?? 'text';
    final text = message['text']?.toString() ?? '';
    _composer.beginReply(
      messageId: parsedId,
      text: text.isNotEmpty
          ? text
          : (type == 'image'
                ? 'Photo'
                : type == 'voice'
                ? 'Voice message'
                : type == 'video'
                ? 'Video'
                : 'Message'),
      type: type,
      name: message['is_sent'] == true ? 'You' : _peerDisplayName,
    );
  }

  void _beginEdit(Map<String, dynamic> message) {
    final id = message['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
    final text = message['text']?.toString() ?? '';
    if (parsedId <= 0 || text.isEmpty) return;
    _composer.beginEdit(
      messageId: parsedId,
      preview: text,
      createdAt: _messageCreatedAt(message),
    );
    ref.read(pendingChatDraftProvider.notifier).state = PendingChatDraft(
      userId: widget.userId,
      text: text,
    );
  }

  Future<void> _submitEdit(String text) async {
    final messageId = _editingMessageId;
    if (messageId == null) return;
    try {
      final updated = await ref
          .read(chatServiceProvider)
          .editMessage(messageId, text);
      if (!mounted) return;
      _thread.mapRows((msg) {
        if (!_sameMessageId(msg['id'], messageId)) return msg;
        return ChatEditedApply.patchRow(
          msg,
          content: text,
          editedAt: updated.editedAt ?? DateTime.now(),
          extra: _messageToMap(updated),
        );
      });
      _composer.clear();
      ref
          .read(chatListPreviewProvider.notifier)
          .applyEditedMessage(
            peerUserId: widget.userId,
            messageId: messageId,
            previewText: text,
          );
    } catch (e) {
      AppLogger.warning('Edit message failed', tag: 'Chat', error: e);
      if (!mounted) return;
      ErrorHandlerService.handleError(context, e);
    }
  }

  Future<void> _deleteOwnMessage(
    Map<String, dynamic> message, {
    required bool forEveryone,
  }) async {
    final id = message['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
    if (parsedId <= 0) return;
    try {
      await ref
          .read(chatServiceProvider)
          .deleteMessage(parsedId, forEveryone: forEveryone);
      if (!mounted) return;
      if (forEveryone) {
        _applyDeletedTombstone(parsedId);
        unawaited(
          ref
              .read(chatLocalRepositoryProvider)
              .markMessageDeletedByServerId(parsedId),
        );
      } else {
        _messages = _messages
            .where((msg) => !_sameMessageId(msg['id'], parsedId))
            .toList();
        unawaited(
          ref
              .read(chatLocalRepositoryProvider)
              .deleteMessageByServerId(parsedId),
        );
      }
      unawaited(_refreshPeerListPreview());
    } catch (e) {
      AppLogger.warning('Delete message failed', tag: 'Chat', error: e);
      if (!mounted) return;
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to delete message',
      );
    }
  }

  Future<void> _refreshPeerListPreview() async {
    final localRepo = ref.read(chatLocalRepositoryProvider);
    final latest = await localRepo.getMessagesForOtherUser(
      widget.userId,
      limit: 1,
      excludeDeleted: true,
    );
    if (!mounted) return;
    final message = latest.isEmpty ? null : latest.first;
    ref
        .read(chatListPreviewProvider.notifier)
        .applyLatestPreview(
          peerUserId: widget.userId,
          lastMessage: message == null
              ? ''
              : chatMessagePreviewText(
                  message: message.message,
                  messageType: message.messageType,
                  mediaDuration: message.mediaDuration,
                  isDeleted: message.isDeleted,
                ),
          lastMessageType: message?.messageType,
          lastMessageTime: message?.createdAt,
          lastMessageFromMe:
              message != null && message.senderId != widget.userId,
          lastMessageId: message?.id,
        );
  }

  DateTime? _messageCreatedAt(Map<String, dynamic> message) {
    final ts = message['timestamp'];
    if (ts is DateTime) return ts;
    return AppDateTime.parseApi(ts?.toString());
  }

  void _applyDeletedTombstone(int messageId) {
    _thread.mapRows((msg) {
      if (!_sameMessageId(msg['id'], messageId)) return msg;
      return {
        ...msg,
        'is_deleted': true,
        'text': '',
        'attachment_url': null,
        'reactions': <String, int>{},
        'my_reaction': null,
      };
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> message) async {
    if (!mounted) return;
    final createdAt = _messageCreatedAt(message);
    final choice = await showChatDeleteConfirmSheet(
      context: context,
      canDeleteForEveryone: ChatMessageSheetActions.canDeleteForEveryone(
        isSent: message['is_sent'] == true,
        createdAt: createdAt,
      ),
    );
    if (choice == null || !mounted) return;
    await _deleteOwnMessage(
      message,
      forEveryone: choice == ChatDeleteChoice.forEveryone,
    );
  }

  Future<void> _showMessageActions(Map<String, dynamic> message, {Offset? at}) {
    if (message['kind'] == 'call') return Future.value();
    if (message['is_deleted'] == true) return Future.value();
    final isSent = message['is_sent'] == true;
    final type = message['type']?.toString() ?? 'text';
    final text = message['text']?.toString();
    final messageId = message['id'] is int ? message['id'] as int : 0;
    final isExpired = message['is_expired'] == true;
    final createdAt = _messageCreatedAt(message);
    final canEdit = ChatMessageSheetActions.canEdit(
      isSent: isSent,
      type: type,
      isExpired: isExpired,
      messageId: messageId,
      createdAt: createdAt,
    );
    final pinnedNow = ref
        .read(chatPinnedBannerProvider(widget.userId))
        .isPinned(messageId);
    final actions = <AppActionSheetItem>[
      AppActionSheetItem(
        iconPath: AppIcons.reply,
        label: 'Reply',
        onTap: () => _beginReply(message),
      ),
      if (ChatMessageSheetActions.canForward(
        messageId: messageId,
        type: type,
        isDeleted: message['is_deleted'] == true,
        isExpired: isExpired,
        isLocked: message['is_locked'] == true,
      ))
        AppActionSheetItem(
          iconPath: AppIcons.forward,
          label: 'Forward',
          onTap: () => unawaited(_openForward(message)),
        ),
      if (ChatMessageSheetActions.canCopy(text, type: type))
        AppActionSheetItem(
          iconPath: AppIcons.copy,
          label: 'Copy',
          onTap: () => unawaited(_copyMessageText(text!)),
        ),
      if (canEdit)
        AppActionSheetItem(
          iconPath: AppIcons.edit2,
          label: 'Edit',
          subtitle: ChatMessageSheetActions.editActionSubtitle(
            createdAt: createdAt,
          ),
          onTap: () => _beginEdit(message),
        ),
      if (ChatMessageSheetActions.canPin(
        messageId: messageId,
        type: type,
        isDeleted: message['is_deleted'] == true,
        isExpired: isExpired,
        isLocked: message['is_locked'] == true,
      ))
        AppActionSheetItem(
          iconPath: pinnedNow ? AppIcons.bookmark2 : AppIcons.bookmark,
          label: pinnedNow ? 'Unpin' : 'Pin',
          onTap: () => unawaited(_togglePin(message)),
        ),
      if (ChatMessageSheetActions.canDelete(
        isSent: isSent,
        messageId: messageId,
        isDeleted: message['is_deleted'] == true,
      ))
        AppActionSheetItem(
          iconPath: AppIcons.delete,
          label: 'Delete',
          iconColor: AppColors.feedbackError,
          onTap: () => unawaited(_confirmDelete(message)),
        ),
      if (ChatMessageSheetActions.canReport(isSent: isSent))
        AppActionSheetItem(
          iconPath: AppIcons.flag,
          label: 'Report',
          onTap: _openReportFromMessage,
        ),
    ];
    final media = MediaQuery.of(context);
    return ChatMessageContextMenu.show(
      context: context,
      anchor: at ?? Offset(media.size.width / 2, media.size.height / 2),
      isSent: isSent,
      actions: actions,
      showReact: ChatMessageSheetActions.canReact(
        messageId: messageId,
        isExpired: isExpired,
      ),
      onReact: (emoji) => _handleReact(message, emoji),
    );
  }

  Future<void> _openForward(Map<String, dynamic> message) async {
    final messageId = message['id'] is int ? message['id'] as int : 0;
    if (messageId <= 0 || !mounted) return;
    final result = await ChatForwardSheet.show(
      context: context,
      messageId: messageId,
    );
    if (result == null || !mounted) return;

    for (final sent in result.forwarded) {
      if (sent.receiverId == widget.userId) {
        _ingestRemoteMessage(sent);
      }
      ref
          .read(chatListPreviewProvider.notifier)
          .bumpOutgoingMessage(
            peerUserId: sent.receiverId,
            previewText: chatMessagePreviewText(
              message: sent.message,
              messageType: sent.messageType,
              mediaDuration: sent.mediaDuration,
            ),
            lastMessageType: sent.messageType,
            timestamp: sent.createdAt,
            lastMessageId: sent.id,
          );
      unawaited(
        ref
            .read(chatLocalRepositoryProvider)
            .upsertMessage(sent, sent.receiverId),
      );
    }

    if (!mounted || result.forwarded.isEmpty) return;
    final n = result.forwarded.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          n == 1 ? 'Forwarded' : 'Forwarded to $n chats',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  void _handleReact(Map<String, dynamic> message, String emoji) {
    unawaited(_reactToMessage(message, emoji));
  }

  Future<void> _reactToMessage(
    Map<String, dynamic> message,
    String emoji,
  ) async {
    final id = message['id'];
    final messageId = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
    if (messageId <= 0) return;
    final previous = ChatReactionSummary.fromMap(message);
    final optimistic = previous.toggle(emoji);
    _patchMessageReactions(messageId, optimistic);
    try {
      final result = await _chatService.reactToMessage(messageId, emoji);
      if (!mounted) return;
      _patchMessageReactions(messageId, result.summary);
    } catch (e) {
      AppLogger.warning(
        'react $emoji on $messageId failed',
        tag: 'Chat',
        error: e,
      );
      if (!mounted) return;
      _patchMessageReactions(messageId, previous);
    }
  }

  void _patchMessageReactions(int messageId, ChatReactionSummary summary) {
    _thread.mapRows((msg) {
      if (!_sameMessageId(msg['id'], messageId)) return msg;
      return {...msg, 'reactions': summary.counts, 'my_reaction': summary.mine};
    });
    _persistReactionSummary(messageId, summary);
  }

  void _persistReactionSummary(int messageId, ChatReactionSummary summary) {
    if (messageId <= 0) return;
    unawaited(_writeReactionSummary(messageId, summary));
  }

  Future<void> _writeReactionSummary(
    int messageId,
    ChatReactionSummary summary,
  ) async {
    if (!mounted) return;
    try {
      await ref
          .read(chatLocalRepositoryProvider)
          .patchMessageReactions(
            serverId: messageId,
            counts: summary.counts,
            mine: summary.mine,
          );
    } catch (e) {
      AppLogger.warning(
        'Failed to persist reactions for $messageId',
        tag: 'Chat',
        error: e,
      );
    }
  }

  Future<void> _copyMessageText(String text) async {
    await ChatCopyFeedback.copy(text);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(ChatCopyFeedback.snackBar(context));
  }

  void _openReportFromMessage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportUserScreen(userId: widget.userId),
      ),
    );
  }

  void _ackIncomingDelivered(Iterable<Message> messages) {
    final me = _currentUserId;
    if (me == null || me <= 0) return;
    final ids = messages
        .where(
          (message) =>
              message.receiverId == me &&
              message.id > 0 &&
              !message.isDelivered &&
              !message.isRead,
        )
        .map((message) => message.id)
        .toList();
    if (ids.isEmpty) return;
    unawaited(
      ref.read(chatServiceProvider).markMessagesDelivered(ids).catchError((e) {
        AppLogger.warning(
          'Failed to ack messages as delivered',
          tag: 'Chat',
          error: e,
        );
      }),
    );
  }

  void _retryFailedMessage(Map<String, dynamic> message) {
    if (!ChatSendRetry.canRetry(message)) return;
    final clientId = message['client_id']?.toString();
    if (clientId == null) return;
    final type = message['type']?.toString() ?? 'text';
    final localPath = message['local_path']?.toString();
    if (type == 'voice') {
      final duration = message['media_duration'] as int? ?? 1;
      unawaited(
        _resendVoice(
          clientId: clientId,
          filePath: localPath,
          durationSeconds: duration,
        ),
      );
      return;
    }
    if (type == 'image' || type == 'video' || type == 'disappearing_image') {
      unawaited(
        _resendMedia(
          clientId: clientId,
          type: type,
          filePath: localPath,
          expiresInSeconds: message['expires_in_seconds'] as int?,
        ),
      );
      return;
    }
    final text = message['text']?.toString() ?? '';
    if (text.isEmpty) return;
    unawaited(_handleSend(text, existingClientId: clientId));
  }

  Future<bool> _handleVoiceRecordStart() async {
    if (await _voiceRecorder.isRecording()) return true;
    if (!mounted) return false;

    final allowed = await ensureChatMediaPermission(
      context,
      ChatMediaPermissionKind.microphone,
    );
    if (!allowed || !mounted) return false;

    final dir = await getTemporaryDirectory();
    _voiceRecordingPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _voiceRecordingDurationSeconds = 0;

    await _voiceRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _voiceRecordingPath!,
    );

    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _voiceRecordingDurationSeconds++;
      if (_voiceRecordingDurationSeconds >= 300) {
        unawaited(_handleVoiceRecordSend());
      }
    });
    return true;
  }

  Future<void> _handleVoiceRecordCancel() async {
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
    _voiceRecordingDurationSeconds = 0;
    if (await _voiceRecorder.isRecording()) {
      await _voiceRecorder.stop();
    }
    _voiceRecordingPath = null;
  }

  Future<void> _handleVoiceRecordSend() async {
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;

    if (!await _voiceRecorder.isRecording()) {
      _voiceRecordingPath = null;
      return;
    }

    final path = await _voiceRecorder.stop();
    final filePath = path ?? _voiceRecordingPath;
    _voiceRecordingPath = null;

    if (filePath == null || !File(filePath).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recording failed')));
      }
      return;
    }

    final duration = _voiceRecordingDurationSeconds > 0
        ? _voiceRecordingDurationSeconds
        : 1;
    _voiceRecordingDurationSeconds = 0;
    if (!mounted) return;
    await _sendVoiceAtPath(filePath, duration);
  }

  Future<void> _sendVoiceAtPath(String filePath, int duration) async {
    final clientId = ChatClientIds.next();
    final sentAt = DateTime.now();
    if (mounted) {
      _messages = [
        ..._messages,
        _optimisticVoiceMap(
          clientId: clientId,
          durationSeconds: duration,
          localPath: filePath,
        ),
      ];
      _scrollToBottom(bounce: true);
      ref
          .read(chatListPreviewProvider.notifier)
          .bumpOutgoingMessage(
            peerUserId: widget.userId,
            previewText: chatMessagePreviewText(
              messageType: 'voice',
              mediaDuration: duration,
            ),
            lastMessageType: 'voice',
            timestamp: sentAt,
          );
    }

    try {
      final chatService = ref.read(chatServiceProvider);
      Message sent;
      if (_conversationId != null && _conversationId! > 0) {
        final upload = await chatService.uploadChatVoice(
          _conversationId!,
          File(filePath),
          duration,
        );
        sent = await chatService.sendMessage(
          widget.userId,
          '',
          messageType: 'voice',
          mediaPath: upload['media_path']?.toString(),
          mediaDuration:
              (upload['media_duration'] as num?)?.toInt() ?? duration,
          clientId: clientId,
        );
      } else {
        sent = await chatService.sendMessage(
          widget.userId,
          '',
          messageType: 'voice',
          mediaFile: File(filePath),
          mediaDuration: duration,
          clientId: clientId,
        );
      }
      if (mounted) {
        _replaceOptimisticMessage(clientId, sent);
        _scrollToBottom();
      }
    } on ApiError catch (e) {
      AppLogger.warning('Send voice failed', tag: 'Chat', error: e);
      if (mounted) {
        _markMessageFailed(clientId);
        if (e.upgradeRequired ||
            e.errorCode == 'CHAT_DAILY_SEND_LIMIT_REACHED') {
          await ChatUpgradeBottomSheet.show(context);
        } else {
          ErrorHandlerService.showErrorSnackBar(context, e);
        }
      }
    } catch (e) {
      AppLogger.warning('Send voice failed', tag: 'Chat', error: e);
      if (mounted) {
        _markMessageFailed(clientId);
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to send voice message',
        );
      }
    }
  }

  Future<void> _resendVoice({
    required String clientId,
    required String? filePath,
    required int durationSeconds,
  }) async {
    if (filePath == null || !File(filePath).existsSync()) return;
    _thread.mapRows((msg) {
      if (msg['client_id'] == clientId) {
        return {...msg, 'delivery_status': MessageDeliveryStatus.sending};
      }
      return msg;
    });
    try {
      final chatService = ref.read(chatServiceProvider);
      Message sent;
      if (_conversationId != null && _conversationId! > 0) {
        final upload = await chatService.uploadChatVoice(
          _conversationId!,
          File(filePath),
          durationSeconds,
        );
        sent = await chatService.sendMessage(
          widget.userId,
          '',
          messageType: 'voice',
          mediaPath: upload['media_path']?.toString(),
          mediaDuration:
              (upload['media_duration'] as num?)?.toInt() ?? durationSeconds,
          clientId: clientId,
        );
      } else {
        sent = await chatService.sendMessage(
          widget.userId,
          '',
          messageType: 'voice',
          mediaFile: File(filePath),
          mediaDuration: durationSeconds,
          clientId: clientId,
        );
      }
      if (mounted) {
        _replaceOptimisticMessage(clientId, sent);
        _scrollToBottom();
      }
    } catch (e) {
      AppLogger.warning('Resend voice failed', tag: 'Chat', error: e);
      if (mounted) _markMessageFailed(clientId);
    }
  }

  Future<void> _resendMedia({
    required String clientId,
    required String type,
    required String? filePath,
    int? expiresInSeconds,
  }) async {
    if (filePath == null || !File(filePath).existsSync()) return;
    final mediaFile = File(filePath);
    _thread.mapRows((msg) {
      if (msg['client_id'] == clientId) {
        return {...msg, 'delivery_status': MessageDeliveryStatus.sending};
      }
      return msg;
    });
    if (type == 'image') {
      ref
          .read(chatImageUploadProgressProvider.notifier)
          .setProgress(clientId, 0);
    }
    try {
      Message sent;
      if ((type == 'image' || type == 'disappearing_image') &&
          _conversationId != null &&
          _conversationId! > 0) {
        try {
          final upload = await ref
              .read(chatServiceProvider)
              .uploadChatImage(
                _conversationId!,
                mediaFile,
                onSendProgress: _imageSendProgressCallback(clientId, type),
              );
          _completeImageUploadProgress(clientId, type);
          sent = await ref
              .read(chatServiceProvider)
              .sendMessage(
                widget.userId,
                '',
                messageType: type,
                mediaPath: upload['media_path']?.toString(),
                mediaThumbnailPath: upload['media_thumbnail_path']?.toString(),
                mediaWidth: upload['width'] as int?,
                mediaHeight: upload['height'] as int?,
                expiresInSeconds: expiresInSeconds,
                clientId: clientId,
              );
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Dedicated image upload failed; falling back to sendMessage multipart',
            tag: 'Chat',
            error: e,
          );
          AppLogger.error(
            'Chat image upload fallback',
            tag: 'Chat',
            error: e,
            stackTrace: stackTrace,
          );
          sent = await ref
              .read(chatServiceProvider)
              .sendMessage(
                widget.userId,
                '',
                messageType: type,
                mediaFile: mediaFile,
                expiresInSeconds: expiresInSeconds,
                clientId: clientId,
              );
        }
      } else {
        sent = await ref
            .read(chatServiceProvider)
            .sendMessage(
              widget.userId,
              '',
              messageType: type,
              mediaFile: mediaFile,
              expiresInSeconds: expiresInSeconds,
              clientId: clientId,
            );
      }
      if (mounted) {
        _replaceOptimisticMessage(clientId, sent);
        _scrollToBottom();
      }
    } catch (e) {
      AppLogger.warning('Resend media failed', tag: 'Chat', error: e);
      if (mounted) _markMessageFailed(clientId);
    }
  }

  void _handleMediaTap() {
    unawaited(
      ChatAttachmentSheet.show(
        context: context,
        onCamera: () =>
            unawaited(_pickAndSendMedia(ImageSource.camera, 'image')),
        onGallery: () =>
            unawaited(_pickAndSendMedia(ImageSource.gallery, 'image')),
        onVoice: () => unawaited(_pickAndSendVoiceFile()),
        onFile: () => unawaited(_pickAndSendDocument()),
        onProfile: () => unawaited(_shareProfileCard()),
        onSelfDestruct: _startSelfDestructPhotoFlow,
      ),
    );
  }

  void _handleMediaLongPress() {
    final theme = Theme.of(context);
    AppActionBottomSheet.show<void>(
      context: context,
      title: 'Send photo',
      actions: [
        AppActionSheetItem(
          iconPath: AppIcons.gallery,
          label: 'Photo',
          iconColor: theme.colorScheme.primary,
          onTap: () {
            Navigator.pop(context);
            _showNormalPhotoSourceSheet();
          },
        ),
        AppActionSheetItem(
          iconPath: AppIcons.flame,
          label: 'Self-Destruct Photo',
          iconColor: AppColors.feedbackWarning,
          onTap: () {
            Navigator.pop(context);
            _startSelfDestructPhotoFlow();
          },
        ),
      ],
    );
  }

  void _showNormalPhotoSourceSheet() {
    final theme = Theme.of(context);
    AppActionBottomSheet.show<void>(
      context: context,
      title: 'Photo',
      actions: [
        AppActionSheetItem(
          iconPath: AppIcons.camera,
          label: 'Take photo',
          iconColor: theme.colorScheme.primary,
          onTap: () {
            Navigator.pop(context);
            _pickAndSendMedia(ImageSource.camera, 'image');
          },
        ),
        AppActionSheetItem(
          iconPath: AppIcons.gallery,
          label: 'Choose from gallery',
          iconColor: theme.colorScheme.secondary,
          onTap: () {
            Navigator.pop(context);
            _pickAndSendMedia(ImageSource.gallery, 'image');
          },
        ),
      ],
    );
  }

  void _startSelfDestructPhotoFlow() {
    final theme = Theme.of(context);
    AppActionBottomSheet.show<void>(
      context: context,
      title: 'Self-destruct photo',
      actions: [
        AppActionSheetItem(
          iconPath: AppIcons.camera,
          label: 'Take self-destruct photo',
          iconColor: theme.colorScheme.primary,
          onTap: () {
            Navigator.pop(context);
            unawaited(_pickSelfDestructPhoto(ImageSource.camera));
          },
        ),
        AppActionSheetItem(
          iconPath: AppIcons.gallery,
          label: 'Choose self-destruct photo',
          iconColor: theme.colorScheme.secondary,
          onTap: () {
            Navigator.pop(context);
            unawaited(_pickSelfDestructPhoto(ImageSource.gallery));
          },
        ),
      ],
    );
  }

  Future<void> _pickSelfDestructPhoto(ImageSource source) async {
    final seconds = await SelfDestructDurationSheet.show(context);
    if (seconds == null || !mounted) return;
    await _pickAndSendMedia(
      source,
      SelfDestructSend.messageType,
      expiresInSeconds: seconds,
    );
  }

  Future<void> _pickAndSendVoiceFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || !mounted) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) return;
    await _sendVoiceAtPath(path, 1);
  }

  Future<void> _pickAndSendDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || !mounted) return;
    final picked = result.files.single;
    final path = picked.path;
    if (path == null || path.isEmpty) return;
    final kind = ChatAttachmentKindResolver.fromName(picked.name);
    final type = ChatAttachmentKindResolver.messageType(kind);
    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This chat can send photos, videos, and voice notes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
      return;
    }
    if (type == 'voice') {
      await _sendVoiceAtPath(path, 1);
      return;
    }
    await _sendMediaFile(File(path), type: type);
  }

  Future<void> _shareProfileCard() async {
    if (!mounted) return;
    await ShareProfileSheet.show(
      context,
      onProfileSelected: (profileUserId, displayName) {
        unawaited(_sendProfileLink(profileUserId, displayName));
      },
    );
  }

  Future<void> _sendProfileLink(int profileUserId, String displayName) async {
    final clientId = ChatClientIds.next();
    _messages = [
      ..._messages,
      {
        ..._optimisticMap(clientId: clientId, text: '', type: 'profile_link'),
        'profile_card': {'user_id': profileUserId, 'display_name': displayName},
      },
    ];
    _scrollToBottom(bounce: true);
    ref
        .read(chatListPreviewProvider.notifier)
        .bumpOutgoingMessage(
          peerUserId: widget.userId,
          previewText: chatMessagePreviewText(messageType: 'profile_link'),
          lastMessageType: 'profile_link',
          timestamp: DateTime.now(),
        );
    try {
      final sent = await ref
          .read(chatServiceProvider)
          .sendProfileLink(widget.userId, profileUserId);
      if (!mounted) return;
      _replaceOptimisticMessage(clientId, sent);
      _scrollToBottom();
    } catch (e) {
      AppLogger.warning('Share profile failed', tag: 'Chat', error: e);
      if (!mounted) return;
      _markMessageFailed(clientId);
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to share profile',
      );
    }
  }

  void _openChatVideo(Map<String, dynamic> message) {
    final url = message['attachment_url']?.toString();
    if (!ChatVideoPlayback.canOpen(
      mediaUrl: url,
      deliveryStatus: ChatDeliveryStatusMap.fromMap(message),
    )) {
      return;
    }
    unawaited(ChatVideoViewer.open(context, videoUrl: url!));
  }

  void _openChatImageGallery(Map<String, dynamic> message) {
    final url = message['attachment_url']?.toString();
    if (url == null || url.isEmpty) return;
    final items = ChatGalleryItems.fromMaps(_messages);
    final index = ChatGalleryItems.indexFor(items, message);
    final id = message['id'] is int
        ? message['id'] as int
        : int.tryParse(message['id']?.toString() ?? '') ?? 0;
    unawaited(
      ChatImageViewer.open(
        context,
        imageUrl: url,
        heroTag: ChatGalleryItem.heroTagFor(
          messageId: id,
          clientId: message['client_id']?.toString(),
        ),
        images: items,
        initialIndex: index,
      ),
    );
  }

  Future<void> _openSelfDestructViewer(Map<String, dynamic> message) async {
    final messageId = message['id'];
    if (messageId is! int || messageId <= 0) return;

    final expired = await SelfDestructViewer.open(
      context,
      messageId: messageId,
      initialRemainingSeconds: message['remaining_seconds'] as int?,
      totalSeconds: message['expires_in_seconds'] as int?,
    );

    if (!mounted) return;
    if (expired != true) return;

    _thread.mapRows((msg) {
      if (msg['id'] == messageId) {
        return {
          ...msg,
          'viewed_at': DateTime.now(),
          'is_expired': true,
          'remaining_seconds': 0,
          'attachment_url': null,
        };
      }
      return msg;
    });
  }

  static const int _maxChatImageBytes = 5 * 1024 * 1024;

  Future<File?> _compressImageIfNeeded(String sourcePath) async {
    final source = File(sourcePath);
    final length = await source.length();
    if (length <= _maxChatImageBytes) {
      return source;
    }

    final targetPath =
        '${(await getTemporaryDirectory()).path}/chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: 75,
      minWidth: 1280,
      minHeight: 1280,
    );
    return result != null ? File(result.path) : source;
  }

  Future<void> _pickAndSendMedia(
    ImageSource source,
    String type, {
    int? expiresInSeconds,
  }) async {
    if (!mounted) return;
    final kind = source == ImageSource.camera
        ? ChatMediaPermissionKind.camera
        : (type == 'video'
              ? ChatMediaPermissionKind.videos
              : ChatMediaPermissionKind.photos);
    final allowed = await ensureChatMediaPermission(context, kind);
    if (!allowed || !mounted) return;

    try {
      final picker = ImagePicker();
      final file = type == 'video'
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source);
      if (file == null || !mounted) return;
      await _sendMediaFile(
        File(file.path),
        type: type,
        expiresInSeconds: expiresInSeconds,
      );
    } catch (e) {
      AppLogger.warning('Pick chat media failed', tag: 'Chat', error: e);
      if (!mounted) return;
      await ChatMediaPermissionSheet.show(
        context,
        kind: kind,
        permanentlyDenied: true,
      );
    }
  }

  Future<void> _sendMediaFile(
    File mediaFile, {
    required String type,
    int? expiresInSeconds,
  }) async {
    String? clientId;
    String? mediaPath;
    try {
      if (type == 'image' || type == 'disappearing_image') {
        final length = await mediaFile.length();
        if (length > _maxChatImageBytes * 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image is too large. Maximum size is 5MB.'),
              ),
            );
          }
          return;
        }
        final compressed = await _compressImageIfNeeded(mediaFile.path);
        if (compressed != null) mediaFile = compressed;
      }

      final optimisticId = ChatClientIds.next();
      clientId = optimisticId;
      mediaPath = mediaFile.path;
      ChatImagePlaceholderData? placeholder;
      if (type == 'image') {
        placeholder = await ChatImagePlaceholder.fromFile(mediaFile.path);
        if (!mounted) return;
      }
      _messages = [
        ..._messages,
        _optimisticMap(
          clientId: optimisticId,
          text: '',
          type: type,
          attachmentUrl: mediaFile.path,
          localPath: mediaFile.path,
          expiresInSeconds: expiresInSeconds,
          placeholderDataUri: placeholder?.dataUri,
          mediaWidth: placeholder?.width,
          mediaHeight: placeholder?.height,
        ),
      ];
      if (type == 'image') {
        ref
            .read(chatImageUploadProgressProvider.notifier)
            .setProgress(optimisticId, 0);
        ref
            .read(chatListPreviewProvider.notifier)
            .bumpOutgoingMessage(
              peerUserId: widget.userId,
              previewText: chatMessagePreviewText(messageType: type),
              lastMessageType: type,
              timestamp: DateTime.now(),
            );
      }
      _scrollToBottom(bounce: true);

      Message sent;
      if ((type == 'image' || type == 'disappearing_image') &&
          _conversationId != null &&
          _conversationId! > 0) {
        try {
          final upload = await ref
              .read(chatServiceProvider)
              .uploadChatImage(
                _conversationId!,
                mediaFile,
                onSendProgress: _imageSendProgressCallback(clientId, type),
              );
          _completeImageUploadProgress(clientId, type);
          sent = await ref
              .read(chatServiceProvider)
              .sendMessage(
                widget.userId,
                '',
                messageType: type,
                mediaPath: upload['media_path']?.toString(),
                mediaThumbnailPath: upload['media_thumbnail_path']?.toString(),
                mediaWidth: upload['width'] as int?,
                mediaHeight: upload['height'] as int?,
                expiresInSeconds: expiresInSeconds,
                clientId: clientId,
              );
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Dedicated image upload failed; falling back to sendMessage multipart',
            tag: 'Chat',
            error: e,
          );
          AppLogger.error(
            'Chat image upload fallback',
            tag: 'Chat',
            error: e,
            stackTrace: stackTrace,
          );
          sent = await ref
              .read(chatServiceProvider)
              .sendMessage(
                widget.userId,
                '',
                messageType: type,
                mediaFile: mediaFile,
                expiresInSeconds: expiresInSeconds,
                clientId: clientId,
              );
        }
      } else {
        sent = await ref
            .read(chatServiceProvider)
            .sendMessage(
              widget.userId,
              '',
              messageType: type,
              mediaFile: mediaFile,
              expiresInSeconds: expiresInSeconds,
              clientId: clientId,
            );
      }

      if (!mounted) return;
      _replaceOptimisticMessage(clientId, sent);
      _scrollToBottom();
    } on ApiError catch (e) {
      AppLogger.warning('Send media failed', tag: 'Chat', error: e);
      if (!mounted) return;
      if (clientId != null) _markMessageFailed(clientId);
      if (e.upgradeRequired || e.errorCode == 'CHAT_DAILY_SEND_LIMIT_REACHED') {
        await ChatUpgradeBottomSheet.show(context);
        return;
      }
      ErrorHandlerService.showErrorSnackBar(
        context,
        e,
        customMessage: 'Failed to send media',
        onRetry: clientId != null
            ? () => _resendMedia(
                clientId: clientId!,
                type: type,
                filePath: mediaPath,
                expiresInSeconds: expiresInSeconds,
              )
            : null,
      );
    } catch (e) {
      AppLogger.warning('Send media failed', tag: 'Chat', error: e);
      if (!mounted) return;
      if (clientId != null) _markMessageFailed(clientId);
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to send media',
        onRetry: clientId != null
            ? () => _resendMedia(
                clientId: clientId!,
                type: type,
                filePath: mediaPath,
                expiresInSeconds: expiresInSeconds,
              )
            : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(chatActiveBackendSyncProvider);
    ref.watch(chatThreadLiveSyncProvider(widget.userId));
    ref.listen<ChatThreadLiveTick?>(chatThreadLiveTickProvider(widget.userId), (
      previous,
      next,
    ) {
      if (next == null || previous?.seq == next.seq) return;
      if (!_isNearBottom()) return;
      _runAfterBuild(() {
        _scrollToBottom(bounce: next.insertedNew);
        if (next.fromPeer) unawaited(_markAsRead());
      });
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChatThreadPageShell(
      peerUserId: widget.userId,
      peerDisplayName: _peerDisplayName,
      peerAvatarUrl: _peerAvatarUrl,
      peerCallPhotoUrl: _peerCallPhotoUrl,
      currentUserId: _currentUserId ?? 0,
      embedded: widget.embedded,
      scrollController: _scrollController,
      threadListKey: _threadListKey,
      unreadSeparatorKey: _unreadSeparatorKey,
      showUnreadSeparator: _showUnreadSeparator,
      openUnreadCount: _openUnreadCount,
      chatBgAsset: isDark
          ? ChatThreadPageShell.backgroundDark
          : ChatThreadPageShell.backgroundLight,
      onLeave: _leaveChat,
      onHeaderTap: _openConversationInfo,
      onVideoCall: () => unawaited(_handleVideoCallTap()),
      onPinnedBannerTap: () => unawaited(_onPinnedBannerTap()),
      onRetryLoad: () => unawaited(_loadMessages(forceRefresh: true)),
      onRetryLoadOlder: () => unawaited(_loadMoreMessages()),
      onSend: (text) => unawaited(_handleSend(text)),
      onJumpToLatest: _jumpToLatest,
      onRedialCall: (call) => unawaited(_redialCall(call)),
      onRetryFailed: _retryFailedMessage,
      onReply: _beginReply,
      onJumpToReply: (message) => unawaited(_jumpToRepliedMessage(message)),
      onReact: _handleReact,
      onLongPress: _showMessageActions,
      onSelfDestructTap: (message) =>
          unawaited(_openSelfDestructViewer(message)),
      onImageTap: _openChatImageGallery,
      onVideoTap: _openChatVideo,
      onVoiceListened: (message) => unawaited(_onVoiceListened(message)),
      onMediaTap: _handleMediaTap,
      onMediaLongPress: _handleMediaLongPress,
      onVoiceRecordStart: _handleVoiceRecordStart,
      onVoiceRecordSend: _handleVoiceRecordSend,
      onVoiceRecordCancel: _handleVoiceRecordCancel,
      onTextChanged: _onTypingChanged,
      onFocusChange: _onComposerFocusChange,
      onKeyboardInset: _onChatKeyboardInset,
      onKeyboardInsetTick: _onChatKeyboardInsetTick,
      onKeyboardInsetSettled: _onChatKeyboardInsetSettled,
    );
  }

  void _leaveChat() {
    if (widget.embedded) {
      widget.onEmbeddedClose?.call();
      return;
    }
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    router?.go('${AppRoutes.home}/chat-list');
  }

  Future<bool> _ensureVideoCallAccess() async {
    final guard = PlanGuard(ref.read(planLimitsServiceProvider));
    final access = await guard.canMakeVideoCall();
    if (!mounted) return false;
    if (!access.isAllowed) {
      final target = Uri(
        path: AppRoutes.featureLocked,
        queryParameters: {
          'title': 'Video calls',
          'desc':
              access.errorMessage ??
              'Upgrade to unlock face-to-face video calling.',
          'minTier': 'silder',
        },
      ).toString();
      context.push(target);
      return false;
    }
    return true;
  }

  Future<void> _handleVideoCallTap() async {
    if (!await _ensureVideoCallAccess()) return;
    await startOutgoingCall(
      context: context,
      ref: ref,
      recipientId: widget.userId,
      recipientName: _peerDisplayName,
      recipientAvatarUrl: _peerCallPhotoUrl,
      type: OutgoingCallType.video,
    );
  }
}
