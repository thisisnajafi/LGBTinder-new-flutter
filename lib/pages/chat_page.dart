// Screen: ChatPage
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_icons.dart';
import '../widgets/chat/chat_header.dart';
import 'chat_conversation_info_page.dart';
import '../widgets/chat/message_input.dart';
import '../widgets/chat/message_reply_widget.dart';
import '../widgets/chat/pinned_messages_banner.dart';
import '../widgets/chat/chat_message_list_tile.dart';
import '../widgets/chat/chat_peer_typing_indicator.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../widgets/loading/skeleton_chat.dart';
import '../features/chat/providers/conversation_mute_cache_provider.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/chat/data/models/message.dart';
import '../features/chat/data/models/message_delivery_status.dart';
import '../features/chat/data/models/sticker_pack.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../features/chat/presentation/widgets/share_profile_sheet.dart';
import '../features/chat/presentation/widgets/chat_upgrade_widgets.dart';
import '../features/chat/presentation/widgets/sticker_picker_sheet.dart';
import '../features/chat/presentation/widgets/self_destruct_viewer.dart';
import '../features/chat/presentation/widgets/voice_recorder_overlay.dart';
import '../features/chat/providers/chat_pusher_providers.dart';
import '../shared/services/pusher_websocket_service.dart';
import '../features/payments/data/services/plan_limits_service.dart';
import '../features/user/providers/user_providers.dart';
import '../features/profile/providers/profile_providers.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../shared/utils/plan_guard.dart';
import '../features/calls/data/models/call.dart';
import '../features/calls/pages/outgoing_call_page.dart';
import '../features/calls/presentation/widgets/call_history_bubble.dart';
import '../features/calls/providers/call_providers.dart';
import '../features/calls/utils/call_log_labels.dart';
import '../features/chat/providers/chat_list_preview_provider.dart';
import '../features/chat/providers/pinned_count_provider.dart';
import '../features/chat/data/services/chat_service.dart';
import '../features/chat/data/local/chat_local_repository.dart';
import '../features/chat/utils/chat_timeline_merger.dart';
import '../features/calls/utils/call_navigation.dart';
import '../routes/app_router.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

/// Chat page - Individual chat conversation screen
class ChatPage extends ConsumerStatefulWidget {
  final int userId;
  final String? userName;
  final String? avatarUrl;

  const ChatPage({
    Key? key,
    required this.userId,
    this.userName,
    this.avatarUrl,
  }) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  static const int _historyPageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  ChatHistoryCursor? _nextCursor;
  bool _hasError = false;
  String? _errorMessage;
  int? _currentUserId;
  List<Map<String, dynamic>> _messages = [];
  String? _repliedToMessage;
  String? _repliedToName;
  String? _repliedToMessageType;
  
  // Pusher real-time state
  int? _conversationId;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<ReadReceiptEvent>? _readReceiptSubscription;
  StreamSubscription<MessageExpiredEvent>? _messageExpiredSubscription;
  StreamSubscription<CallSignalingEvent>? _callEventSubscription;
  bool _isOnline = false;
  DateTime? _lastSeenAt;
  String? _resolvedUserName;
  String? _resolvedAvatarUrl;
  bool _conversationMuted = false;
  Timer? _outboundTypingStopTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _resolvedUserName = widget.userName;
    _resolvedAvatarUrl = widget.avatarUrl;
    _loadCurrentUserId();
    if (widget.userId > 0) {
      _resolvePeerDisplayIfNeeded();
      _loadMessages();
      _initializePusherListeners();
      _loadConversationMuteStatus();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid conversation. Please go back and try again.';
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _messageExpiredSubscription?.cancel();
    _callEventSubscription?.cancel();
    _outboundTypingStopTimer?.cancel();
    unawaited(ref.read(chatPusherLifecycleProvider.notifier).closeConversation());
    _scrollController.dispose();
    _messageController.dispose();
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

  Future<void> _resolvePeerDisplayIfNeeded() async {
    final hasName = widget.userName != null &&
        widget.userName!.trim().isNotEmpty &&
        widget.userName!.trim() != 'User';
    final hasAvatar =
        widget.avatarUrl != null && widget.avatarUrl!.trim().isNotEmpty;
    if (hasName && hasAvatar) return;

    try {
      final profile =
          await ref.read(profileServiceProvider).getUserProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        if (!hasName) {
          final first = profile.firstName.trim();
          if (first.isNotEmpty) _resolvedUserName = first;
        }
        if (!hasAvatar &&
            profile.images != null &&
            profile.images!.isNotEmpty) {
          _resolvedAvatarUrl = profile.images!.first.imageUrl;
        }
      });
    } catch (e) {
      AppLogger.warning(
        'Could not resolve chat peer display',
        tag: 'ChatPage',
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
          isOnline: _isOnline,
        ),
      ),
    );
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final userService = ref.read(userServiceProvider);
      final userInfo = await userService.getUserInfo();
      if (mounted) {
        setState(() {
          _currentUserId = userInfo.id;
          // Recompute send/receive flags once current user is known.
          _messages = _messages
              .map((msg) {
                final senderId = msg['sender_id'] as int?;
                if (senderId == null) return msg;
                return {
                  ...msg,
                  'is_sent': senderId == userInfo.id,
                };
              })
              .toList();
        });
      }
    } catch (e) {
      // If user info fails, we'll determine sent status from message senderId
      // Messages where senderId != widget.userId are from current user
    }
  }

  Future<void> _loadConversationMuteStatus() async {
    try {
      final muted =
          await ref.read(chatServiceProvider).isConversationMuted(widget.userId);
      if (!mounted) return;
      ref
          .read(conversationMuteCacheProvider.notifier)
          .setMuted(widget.userId, muted);
      setState(() => _conversationMuted = muted);
    } catch (e) { AppLogger.warning('Silently caught exception', tag: 'chat_page', error: e); }
  }

  void _initializePusherListeners() {
    final pusher = ref.read(pusherWebSocketServiceProvider);

    _messageSubscription = pusher.messageStream.listen((message) {
      if (!mounted) return;
      if (message.senderId != widget.userId &&
          message.receiverId != widget.userId) {
        return;
      }
      setState(() {
        if (message.id > 0 && _messages.any((msg) => msg['id'] == message.id)) {
          return;
        }
        _messages = _messages
            .where((msg) =>
                msg['client_id'] == null ||
                msg['delivery_status'] != MessageDeliveryStatus.sending ||
                msg['text'] != message.message)
            .toList();
        _messages.add(_messageToMap(message));
      });
      _scrollToBottom();
    });

    _readReceiptSubscription = pusher.readReceiptStream.listen((event) {
      if (!mounted) return;
      if (_conversationId != null &&
          event.conversationId != null &&
          event.conversationId != _conversationId) {
        return;
      }
      if (event.readerId != widget.userId) return;

      setState(() {
        _messages = _messages.map((msg) {
          if (msg['is_sent'] != true) return msg;
          final id = msg['id'];
          if (event.messageIds.isEmpty) {
            return {...msg, 'is_read': true};
          }
          if (id is int && event.messageIds.contains(id)) {
            return {...msg, 'is_read': true};
          }
          return msg;
        }).toList();
      });
    });

    _messageExpiredSubscription = pusher.messageExpiredStream.listen((event) {
      if (!mounted) return;
      if (_conversationId != null &&
          event.conversationId != null &&
          event.conversationId != _conversationId) {
        return;
      }
      setState(() {
        _messages = _messages.map((msg) {
          final id = msg['id'];
          if (id is int && id == event.messageId) {
            return {
              ...msg,
              'is_expired': true,
              'remaining_seconds': 0,
              'attachment_url': null,
            };
          }
          return msg;
        }).toList();
      });
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

  Future<void> _handleCallTimelineEvent(CallSignalingEvent event) async {
    final callId = event.payload['call_id']?.toString();
    if (callId == null || callId.isEmpty) return;

    try {
      final call = await ref.read(callServiceProvider).getCall(callId);
      final involvesPeer = call.callerId == widget.userId ||
          call.receiverId == widget.userId;
      if (!involvesPeer || !CallLogLabels.isTerminalStatus(call.status)) {
        return;
      }
      _appendCallEntry(call);
    } catch (e) { AppLogger.warning('Silently caught exception', tag: 'chat_page', error: e); }
  }

  void _appendCallEntry(Call call) {
    if (_messages.any(
      (item) => item['kind'] == 'call' && item['call_id'] == call.id,
    )) {
      return;
    }

    setState(() {
      final messageItems = _messages
          .where((item) => item['kind'] != 'call')
          .toList();
      final callItems = _messages
          .where((item) => item['kind'] == 'call')
          .toList()
        ..add(_callToMap(call));
      _messages = ChatTimelineMerger.merge(
        messages: messageItems,
        calls: callItems,
      );
    });
    _scrollToBottom();
  }

  Future<void> _subscribePusherConversation(int conversationId) async {
    _conversationId = conversationId;
    await ref.read(chatPusherLifecycleProvider.notifier).openConversation(
          conversationId: conversationId,
          otherUserId: widget.userId,
        );
  }

  void _onTypingChanged(String text) {
    _outboundTypingStopTimer?.cancel();
    final chatService = ref.read(chatServiceProvider);
    final hasText = text.trim().isNotEmpty;

    Future<void> sendTyping(bool isTyping) async {
      try {
        final conversationId = _conversationId;
        if (conversationId != null && conversationId > 0) {
          await chatService.setConversationTyping(conversationId, isTyping);
        } else {
          await chatService.setTypingStatus(widget.userId, isTyping);
        }
      } catch (e) {
        AppLogger.warning(
          'Typing indicator failed (non-blocking)',
          tag: 'chat_page',
          error: e,
        );
      }
    }

    if (hasText) {
      unawaited(sendTyping(true));
      _outboundTypingStopTimer = Timer(const Duration(seconds: 3), () {
        unawaited(sendTyping(false));
      });
    } else {
      unawaited(sendTyping(false));
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMoreMessages) {
      return;
    }
    if (_scrollController.position.pixels <= 120) {
      unawaited(_loadMoreMessages());
    }
  }

  Future<void> _loadMessages({bool forceRefresh = false}) async {
    if (widget.userId <= 0) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Invalid conversation. Please go back and try again.';
        });
      }
      return;
    }

    final localRepo = ref.read(chatLocalRepositoryProvider);
    var showedCache = false;
    try {
      final cached = await localRepo.getAllMessagesForOtherUser(widget.userId);
      final pagination = await localRepo.loadHistoryPagination(widget.userId);
      if (cached.isNotEmpty && mounted) {
        showedCache = true;
        setState(() {
          _messages = cached.map(_messageToMap).toList();
          _isLoading = false;
          _hasError = false;
          _errorMessage = null;
          _hasMoreMessages = pagination?.hasMore ?? cached.length >= _historyPageSize;
          _nextCursor = pagination?.nextCursor;
        });
        _scrollToBottom();
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached chat messages', tag: 'chat_page', error: e);
    }

    setState(() {
      _isLoading = !showedCache;
      _hasError = false;
      _errorMessage = null;
      if (forceRefresh) {
        _hasMoreMessages = true;
        _nextCursor = null;
      }
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final history = await chatService.getChatHistory(
        receiverId: widget.userId,
        page: 1,
        limit: _historyPageSize,
        forceRefresh: forceRefresh,
      );

      List<Call> calls = [];
      try {
        calls = await ref.read(getCallHistoryUseCaseProvider).execute(
              peerUserId: widget.userId,
              limit: 50,
            );
      } catch (e) {
        AppLogger.warning('Silently caught exception', tag: 'chat_page', error: e);
      }

      if (mounted) {
        final messageMaps =
            history.messages.map((message) => _messageToMap(message)).toList();
        final callMaps = calls
            .where((call) => CallLogLabels.isTerminalStatus(call.status))
            .map(_callToMap)
            .toList();

        final merged = ChatTimelineMerger.merge(
          messages: messageMaps,
          calls: callMaps,
        );

        if (showedCache && !forceRefresh) {
          final existingIds = _messages
              .where((item) => item['kind'] != 'call')
              .map((item) => item['id'])
              .whereType<int>()
              .toSet();
          final newFromNetwork = messageMaps
              .where((m) => !existingIds.contains(m['id']))
              .toList();
          setState(() {
            if (newFromNetwork.isNotEmpty) {
              _messages = ChatTimelineMerger.merge(
                messages: [
                  ..._messages.where((item) => item['kind'] != 'call'),
                  ...newFromNetwork,
                ],
                calls: [
                  ...merged.where((item) => item['kind'] == 'call'),
                  ..._messages.where((item) => item['kind'] == 'call'),
                ],
              );
            }
            _isLoading = false;
            _hasMoreMessages = history.hasMore;
            _nextCursor = history.nextCursor;
          });
        } else {
          setState(() {
            _messages = merged;
            _isLoading = false;
            _hasMoreMessages = history.hasMore;
            _nextCursor = history.nextCursor;
          });
          _scrollToBottom();
        }
        unawaited(
          localRepo.upsertMessages(history.messages, widget.userId),
        );
        unawaited(
          localRepo.saveHistoryPagination(
            widget.userId,
            ChatHistoryPaginationMeta(
              hasMore: history.hasMore,
              nextCursor: history.nextCursor,
            ),
          ),
        );

        if (!showedCache || forceRefresh) {
          _scrollToBottom();
        }

        final conversationId = history.conversationId;
        if (conversationId != null && conversationId > 0) {
          await _subscribePusherConversation(conversationId);
        }

        await _markAsRead();
      }
    } on ApiError catch (e) {
      if (mounted && !showedCache) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !showedCache) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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

    final newMessageMaps = older
        .where((message) => !existingMessageIds.contains(message.id))
        .map(_messageToMap)
        .toList();
    if (newMessageMaps.isEmpty) return false;

    final previousMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final previousPixels =
        _scrollController.hasClients ? _scrollController.position.pixels : 0.0;

    final existingMessages =
        _messages.where((item) => item['kind'] != 'call').toList();
    final callItems = _messages.where((item) => item['kind'] == 'call').toList();

    setState(() {
      _messages = ChatTimelineMerger.merge(
        messages: [...newMessageMaps, ...existingMessages],
        calls: callItems,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final newMaxExtent = _scrollController.position.maxScrollExtent;
      final delta = newMaxExtent - previousMaxExtent;
      if (delta > 0) {
        _scrollController.jumpTo(previousPixels + delta);
      }
    });
    return true;
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoading || _isLoadingMore || !_hasMoreMessages) return;

    setState(() => _isLoadingMore = true);

    try {
      final loadedFromCache = await _loadMoreFromCache();
      if (loadedFromCache) {
        if (mounted) setState(() => _isLoadingMore = false);
        return;
      }
    } catch (_) {
      // Fall through to network pagination.
    }

    final cursor = _nextCursor;
    if (cursor == null) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreMessages = false;
        });
      }
      return;
    }

    final previousMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final previousPixels =
        _scrollController.hasClients ? _scrollController.position.pixels : 0.0;

    try {
      final chatService = ref.read(chatServiceProvider);
      final localRepo = ref.read(chatLocalRepositoryProvider);
      final history = await chatService.getChatHistory(
        receiverId: widget.userId,
        limit: _historyPageSize,
        beforeId: cursor.beforeId,
        beforeCreatedAt: cursor.beforeCreatedAt,
      );

      if (!mounted) return;

      final existingMessageIds = _messages
          .where((item) => item['kind'] != 'call')
          .map((item) => item['id'])
          .whereType<int>()
          .toSet();

      final newMessageMaps = history.messages
          .where((message) => !existingMessageIds.contains(message.id))
          .map((message) => _messageToMap(message))
          .toList();

      if (newMessageMaps.isEmpty) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreMessages = history.hasMore;
          _nextCursor = history.nextCursor;
        });
        unawaited(
          localRepo.saveHistoryPagination(
            widget.userId,
            ChatHistoryPaginationMeta(
              hasMore: history.hasMore,
              nextCursor: history.nextCursor,
            ),
          ),
        );
        return;
      }

      final existingMessages = _messages
          .where((item) => item['kind'] != 'call')
          .toList();
      final callItems =
          _messages.where((item) => item['kind'] == 'call').toList();

      setState(() {
        _messages = ChatTimelineMerger.merge(
          messages: [...newMessageMaps, ...existingMessages],
          calls: callItems,
        );
        _isLoadingMore = false;
        _hasMoreMessages = history.hasMore;
        _nextCursor = history.nextCursor;
      });

      unawaited(
        localRepo.upsertMessages(history.messages, widget.userId),
      );
      unawaited(
        localRepo.saveHistoryPagination(
          widget.userId,
          ChatHistoryPaginationMeta(
            hasMore: history.hasMore,
            nextCursor: history.nextCursor,
          ),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final newMaxExtent = _scrollController.position.maxScrollExtent;
        final delta = newMaxExtent - previousMaxExtent;
        if (delta > 0) {
          _scrollController.jumpTo(previousPixels + delta);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
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

  Future<void> _redialCall(Call call) async {
    if (call.isVideoCall && !await _ensureVideoCallAccess()) return;
    await startOutgoingCall(
      context: context,
      ref: ref,
      recipientId: widget.userId,
      recipientName: _peerDisplayName,
      recipientAvatarUrl: _peerAvatarUrl,
      type: call.isVideoCall ? OutgoingCallType.video : OutgoingCallType.voice,
    );
  }

  Map<String, dynamic> _messageToMap(Message message) {
    final isSent = _currentUserId != null
        ? message.senderId == _currentUserId
        : message.senderId != widget.userId;
    return {
      'id': message.id,
      'client_id': message.clientId,
      'text': message.message,
      'is_sent': isSent,
      'sender_id': message.senderId,
      'timestamp': message.createdAt,
      'is_read': message.isRead,
      'type': message.messageType,
      'attachment_url': message.attachmentUrl ?? message.mediaThumbnailUrl,
      'is_locked': message.isLocked,
      'is_blurred': message.isBlurred,
      'profile_card': message.profileCard,
      'hero_tag': message.id > 0 ? 'chat_image_${message.id}' : message.clientId,
      'delivery_status': message.deliveryStatus,
      'remaining_seconds': message.remainingSeconds,
      'is_expired': message.isExpired,
      'viewed_at': message.viewedAt,
      'secure_media_url': message.secureMediaUrl,
      'media_duration': message.mediaDuration,
    };
  }

  MessageDeliveryStatus _deliveryStatusFromMap(Map<String, dynamic> msg) {
    final raw = msg['delivery_status'];
    if (raw is MessageDeliveryStatus) return raw;
    if (raw is String) {
      switch (raw) {
        case 'sending':
          return MessageDeliveryStatus.sending;
        case 'failed':
          return MessageDeliveryStatus.failed;
        default:
          return MessageDeliveryStatus.sent;
      }
    }
    if (msg['is_sending'] == true) return MessageDeliveryStatus.sending;
    return MessageDeliveryStatus.sent;
  }

  Map<String, dynamic> _optimisticMap({
    required String clientId,
    required String text,
    String type = 'text',
    String? attachmentUrl,
  }) {
    return {
      'id': 0,
      'client_id': clientId,
      'text': text,
      'is_sent': true,
      'sender_id': _currentUserId,
      'timestamp': DateTime.now(),
      'is_read': false,
      'type': type,
      'attachment_url': attachmentUrl,
      'delivery_status': MessageDeliveryStatus.sending,
    };
  }

  void _markMessageFailed(String clientId) {
    setState(() {
      _messages = _messages.map((msg) {
        if (msg['client_id'] == clientId) {
          return {...msg, 'delivery_status': MessageDeliveryStatus.failed};
        }
        return msg;
      }).toList();
    });
  }

  void _replaceOptimisticMessage(String clientId, Message serverMessage) {
    setState(() {
      _messages = _messages
          .where((msg) => msg['client_id'] != clientId)
          .toList()
        ..add(_messageToMap(serverMessage));
    });
  }

  Future<void> _markAsRead() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.markAsRead(widget.userId);
      ref.read(chatListPreviewProvider.notifier).clearUnreadForPeer(widget.userId);
    } catch (e) {
      // Silently fail - marking as read is not critical
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
      showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text('Pinned messages'),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pinned.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final msg = pinned[index];
                      return ListTile(
                        title: Text(
                          msg.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          msg.createdAt.toLocal().toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load pinned messages.')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text, {String? existingClientId}) async {
    if (text.trim().isEmpty) return;

    final clientId =
        existingClientId ?? 'local_${DateTime.now().millisecondsSinceEpoch}';

    if (existingClientId == null) {
      setState(() {
        _messages.add(_optimisticMap(clientId: clientId, text: text));
        _repliedToMessage = null;
        _repliedToName = null;
        _repliedToMessageType = null;
      });
      _messageController.clear();
    } else {
      setState(() {
        _messages = _messages.map((msg) {
          if (msg['client_id'] == clientId) {
            return {
              ...msg,
              'delivery_status': MessageDeliveryStatus.sending,
            };
          }
          return msg;
        }).toList();
      });
    }
    _scrollToBottom();

    try {
      final sentMessage = await ref.read(chatServiceProvider).sendMessage(
            widget.userId,
            text,
            messageType: 'text',
          );

      if (mounted) {
        _replaceOptimisticMessage(clientId, sentMessage);
        _scrollToBottom();
      }
    } on ApiError catch (e) {
      if (mounted) {
        _markMessageFailed(clientId);
        if (e.upgradeRequired || e.errorCode == 'CHAT_DAILY_SEND_LIMIT_REACHED') {
          await ChatUpgradeBottomSheet.show(context);
        } else {
          ErrorHandlerService.showErrorSnackBar(
            context,
            e,
            onRetry: () => _handleSend(text, existingClientId: clientId),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _markMessageFailed(clientId);
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to send message',
          onRetry: () => _handleSend(text, existingClientId: clientId),
        );
      }
    }
  }

  void _retryFailedMessage(Map<String, dynamic> message) {
    final clientId = message['client_id']?.toString();
    final text = message['text']?.toString() ?? '';
    if (clientId == null || text.isEmpty) return;
    unawaited(_handleSend(text, existingClientId: clientId));
  }

  void _handleVoiceTap() {
    VoiceRecorderOverlay.show(
      context,
      receiverId: widget.userId,
      conversationId: _conversationId,
    );
  }

  void _handleMediaTap() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: AppSvgIcon(assetPath: AppIcons.gallery, size: 22),
                title: const Text('Send photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(ImageSource.gallery, 'image');
                },
              ),
              ListTile(
                leading: AppSvgIcon(assetPath: AppIcons.timer, size: 22),
                title: const Text('Self-destruct photo'),
                onTap: () {
                  Navigator.pop(context);
                  _startSelfDestructPhotoFlow();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMediaLongPress() {
    _startSelfDestructPhotoFlow();
  }

  void _startSelfDestructPhotoFlow() {
    SelfDestructDurationSheet.show(
      context,
      onSelected: (seconds) {
        _pickAndSendMedia(
          ImageSource.gallery,
          'disappearing_image',
          expiresInSeconds: seconds,
        );
      },
    );
  }

  Future<void> _openSelfDestructViewer(Map<String, dynamic> message) async {
    final messageId = message['id'];
    if (messageId is! int || messageId <= 0) return;

    final expired = await SelfDestructViewer.open(
      context,
      messageId: messageId,
      initialRemainingSeconds: message['remaining_seconds'] as int?,
    );

    if (!mounted) return;

    setState(() {
      _messages = _messages.map((msg) {
        if (msg['id'] == messageId) {
          return {
            ...msg,
            'viewed_at': DateTime.now(),
            'is_expired': expired == true,
            'remaining_seconds': expired == true ? 0 : msg['remaining_seconds'],
            if (expired == true) 'attachment_url': null,
          };
        }
        return msg;
      }).toList();
    });
  }

  static const int _maxChatImageBytes = 5 * 1024 * 1024;

  Future<File?> _compressImageIfNeeded(String sourcePath) async {
    final source = File(sourcePath);
    final length = await source.length();
    if (length <= _maxChatImageBytes) {
      return source;
    }

    final targetPath = '${(await getTemporaryDirectory()).path}/chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
    String? clientId;
    try {
      final picker = ImagePicker();
      final file = type == 'video'
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source);
      if (file == null || !mounted) return;

      File mediaFile = File(file.path);
      if (type == 'image' || type == 'disappearing_image') {
        final length = await mediaFile.length();
        if (length > _maxChatImageBytes * 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image is too large. Maximum size is 5MB.')),
            );
          }
          return;
        }
        final compressed = await _compressImageIfNeeded(file.path);
        if (compressed != null) mediaFile = compressed;
      }

      clientId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final label = type == 'disappearing_image'
          ? 'Sending self-destruct photo...'
          : (type == 'video' ? 'Sending video...' : 'Sending image...');
      setState(() {
        _messages.add(_optimisticMap(
          clientId: clientId!,
          text: label,
          type: type,
          attachmentUrl: mediaFile.path,
        ));
      });
      _scrollToBottom();

      Message sent;
      if ((type == 'image' || type == 'disappearing_image') &&
          _conversationId != null &&
          _conversationId! > 0) {
        try {
          final upload = await ref.read(chatServiceProvider).uploadChatImage(
                _conversationId!,
                mediaFile,
              );
          sent = await ref.read(chatServiceProvider).sendMessage(
                widget.userId,
                '',
                messageType: type,
                mediaPath: upload['media_path']?.toString(),
                mediaThumbnailPath: upload['media_thumbnail_path']?.toString(),
                mediaWidth: upload['width'] as int?,
                mediaHeight: upload['height'] as int?,
                expiresInSeconds: expiresInSeconds,
              );
        } catch (_) {
          sent = await ref.read(chatServiceProvider).sendMessage(
                widget.userId,
                '',
                messageType: type,
                mediaFile: mediaFile,
                expiresInSeconds: expiresInSeconds,
              );
        }
      } else {
        sent = await ref.read(chatServiceProvider).sendMessage(
              widget.userId,
              '',
              messageType: type,
              mediaFile: mediaFile,
              expiresInSeconds: expiresInSeconds,
            );
      }

      if (!mounted) return;
      _replaceOptimisticMessage(clientId, sent);
      _scrollToBottom();
    } on ApiError catch (e) {
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
            ? () => _pickAndSendMedia(source, type)
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      if (clientId != null) _markMessageFailed(clientId);
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to send media',
        onRetry: clientId != null
            ? () => _pickAndSendMedia(source, type)
            : null,
      );
    }
  }

  void _handleShareProfileTap() {
    ShareProfileSheet.show(
      context,
      onProfileSelected: (profileUserId, displayName) {
        unawaited(_handleProfileLinkSend(profileUserId, displayName));
      },
    );
  }

  Future<void> _handleProfileLinkSend(int profileUserId, String displayName,
      {String? existingClientId}) async {
    final clientId =
        existingClientId ?? 'local_profile_${DateTime.now().millisecondsSinceEpoch}';

    if (existingClientId == null) {
      setState(() {
        _messages.add(_optimisticMap(
          clientId: clientId,
          text: displayName,
          type: 'profile_link',
        ));
      });
    }
    _scrollToBottom();

    try {
      final sent = await ref.read(chatServiceProvider).sendProfileLink(
            widget.userId,
            profileUserId,
          );
      if (mounted) {
        _replaceOptimisticMessage(clientId, sent);
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      _markMessageFailed(clientId);
      if (e.upgradeRequired) {
        await ChatUpgradeBottomSheet.show(context);
      } else {
        ErrorHandlerService.showErrorSnackBar(context, e);
      }
    } catch (e) {
      if (mounted) {
        _markMessageFailed(clientId);
        ErrorHandlerService.handleError(context, e, customMessage: 'Failed to share profile');
      }
    }
  }

  void _handleEmojiTap() {
    StickerPickerSheet.show(
      context,
      onStickerSelected: (StickerItem sticker) {
        unawaited(_handleStickerSend(sticker));
      },
    );
  }

  Future<void> _handleStickerSend(StickerItem sticker, {String? existingClientId}) async {
    final clientId =
        existingClientId ?? 'local_sticker_${DateTime.now().millisecondsSinceEpoch}';

    if (existingClientId == null) {
      setState(() {
        _messages.add(_optimisticMap(
          clientId: clientId,
          text: sticker.id.toString(),
          type: 'sticker',
          attachmentUrl: sticker.imageUrl,
        ));
      });
    } else {
      setState(() {
        _messages = _messages.map((msg) {
          if (msg['client_id'] == clientId) {
            return {
              ...msg,
              'delivery_status': MessageDeliveryStatus.sending,
            };
          }
          return msg;
        }).toList();
      });
    }
    _scrollToBottom();

    try {
      final sentMessage = await ref.read(chatServiceProvider).sendSticker(
            widget.userId,
            sticker.id,
          );

      if (mounted) {
        _replaceOptimisticMessage(clientId, sentMessage);
        _scrollToBottom();
      }
    } on ApiError catch (e) {
      if (mounted) {
        _markMessageFailed(clientId);
        if (e.upgradeRequired || e.errorCode == 'CHAT_DAILY_SEND_LIMIT_REACHED') {
          await ChatUpgradeBottomSheet.show(context);
        } else {
          ErrorHandlerService.showErrorSnackBar(
            context,
            e,
            onRetry: () => _handleStickerSend(sticker, existingClientId: clientId),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _markMessageFailed(clientId);
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to send sticker',
          onRetry: () => _handleStickerSend(sticker, existingClientId: clientId),
        );
      }
    }
  }

  static const String _chatBgLight = 'assets/images/chat/chat-light.png';
  static const String _chatBgDark = 'assets/images/chat/chat-dark.png';

  Future<bool> _ensureVideoCallAccess() async {
    final guard = PlanGuard(ref.read(planLimitsServiceProvider));
    final access = await guard.canMakeVideoCall();
    if (!mounted) return false;
    if (!access.isAllowed) {
      final target = Uri(
        path: AppRoutes.featureLocked,
        queryParameters: {
          'title': 'Video calls',
          'desc': access.errorMessage ??
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
      recipientAvatarUrl: _peerAvatarUrl,
      type: OutgoingCallType.video,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final chatBgAsset = isDark ? _chatBgDark : _chatBgLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          64 + MediaQuery.paddingOf(context).top,
        ),
        child: SafeArea(
          bottom: false,
          child: ChatHeader(
          userId: widget.userId,
          name: _peerDisplayName,
          avatarUrl: _peerAvatarUrl,
          isOnline: _isOnline,
          lastSeenAt: _lastSeenAt,
          onBack: () => Navigator.of(context).pop(),
          onHeaderTap: _openConversationInfo,
          onInfo: _openConversationInfo,
          onCall: () {
            startOutgoingCall(
              context: context,
              ref: ref,
              recipientId: widget.userId,
              recipientName: _peerDisplayName,
              recipientAvatarUrl: _peerAvatarUrl,
              type: OutgoingCallType.voice,
            );
          },
          onVideoCall: () {
            _handleVideoCallTap();
          },
        ),
        ),
      ),
      body: Column(
        children: [
          if (_conversationMuted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.feedbackWarning.withValues(alpha: 0.15),
              child: Row(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.bellSlash,
                    size: 16,
                    color: AppColors.feedbackWarning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifications muted for this chat',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
        fit: StackFit.expand,
        children: [
          // Themed chat background (assets/images/chat/chat-light.png | chat-dark.png)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(chatBgAsset),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
          _PinnedMessagesBannerSection(
            userId: widget.userId,
            onTap: _showPinnedMessages,
          ),
          // Messages list
          Expanded(
            child: _isLoading
                ? SkeletonChat()
                : _hasError
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage ?? 'Failed to load messages',
                        onRetry: () => _loadMessages(forceRefresh: true),
                      )
                    : _messages.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () => _loadMessages(forceRefresh: true),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Text(
                                    'No messages yet',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              if (_isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () => _loadMessages(forceRefresh: true),
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final item = _messages[index];
                                      if (item['kind'] == 'call' &&
                                          item['call'] is Call) {
                                        return CallHistoryBubble(
                                          call: item['call'] as Call,
                                          currentUserId: _currentUserId ?? 0,
                                          timestamp: item['timestamp'] is DateTime
                                              ? item['timestamp'] as DateTime
                                              : null,
                                          onTap: () => _redialCall(
                                            item['call'] as Call,
                                          ),
                                        );
                                      }

                                      final message = item;
                                      final deliveryStatus =
                                          _deliveryStatusFromMap(message);
                                      return ChatMessageListTile(
                                        message: message,
                                        deliveryStatus: deliveryStatus,
                                        onRetry: deliveryStatus ==
                                                MessageDeliveryStatus.failed
                                            ? () => _retryFailedMessage(message)
                                            : null,
                                        onSelfDestructTap:
                                            message['is_sent'] != true &&
                                                    message['is_expired'] != true
                                                ? () => _openSelfDestructViewer(message)
                                                : null,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              ChatPeerTypingIndicator(
                                peerUserId: widget.userId,
                                displayName: _peerDisplayName,
                              ),
                            ],
                          ),
          ),
          // Reply preview
          if (_repliedToMessage != null)
            MessageReplyWidget(
              repliedToName: _repliedToName,
              repliedToMessage: _repliedToMessage,
              repliedToMessageType: _repliedToMessageType,
              onCancel: () {
                setState(() {
                  _repliedToMessage = null;
                  _repliedToName = null;
                  _repliedToMessageType = null;
                });
              },
            ),
          // Message input
          MessageInput(
            onSend: _handleSend,
            onMediaTap: _handleMediaTap,
            onMediaLongPress: _handleMediaLongPress,
            onVoiceTap: _handleVoiceTap,
            onEmojiTap: _handleEmojiTap,
            onShareTap: _handleShareProfileTap,
            hintText: 'Type a message...',
            onTextChanged: _onTypingChanged,
          ),
            ],
          ),
        ],
            ),
          ),
        ],
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
    final asyncCount = ref.watch(pinnedCountProvider(userId));
    return asyncCount.when(
      data: (pinnedCount) {
        if (pinnedCount == 0) return const SizedBox.shrink();
        return PinnedMessagesBanner(
          pinnedCount: pinnedCount,
          onTap: onTap,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
