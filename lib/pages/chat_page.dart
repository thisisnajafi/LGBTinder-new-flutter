// Screen: ChatPage
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../widgets/chat/chat_header.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/message_input.dart';
import '../widgets/chat/message_reply_widget.dart';
import '../widgets/chat/pinned_messages_banner.dart';
import '../widgets/chat/typing_indicator.dart';
import '../core/widgets/loading_indicator.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../widgets/loading/skeleton_chat.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/chat/data/models/message.dart';
import '../features/chat/data/services/websocket_service.dart';
import '../features/payments/data/services/plan_limits_service.dart';
import '../features/user/providers/user_providers.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../shared/utils/plan_guard.dart';
import '../screens/video_call_screen.dart';
import '../screens/voice_call_screen.dart';
import '../routes/app_router.dart';

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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int? _currentUserId;
  List<Map<String, dynamic>> _messages = [];
  String? _repliedToMessage;
  String? _repliedToName;
  String? _repliedToMessageType;
  
  // WebSocket state
  WebSocketService? _webSocketService;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<Map<String, dynamic>>? _onlineStatusSubscription;
  bool _isOtherUserTyping = false;
  bool _isOnline = false;
  DateTime? _lastSeenAt;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    if (widget.userId > 0) {
      _loadMessages();
      _initializeWebSocket();
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
    _typingSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _typingTimer?.cancel();
    _webSocketService?.leaveChat(widget.userId);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
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

  Future<void> _initializeWebSocket() async {
    try {
      _webSocketService = ref.read(webSocketServiceProvider);
      
      // Connect if not already connected
      if (!_webSocketService!.isConnected) {
        await _webSocketService!.connect();
      }
      
      // Join chat room
      _webSocketService!.joinChat(widget.userId);
      
      // Listen for new messages
      _messageSubscription = _webSocketService!.messageStream.listen((message) {
        if (mounted && (message.senderId == widget.userId || message.receiverId == widget.userId)) {
          setState(() {
            // Check if message already exists (avoid duplicates)
            final exists = _messages.any((msg) => msg['id'] == message.id);
            if (!exists) {
              _messages.add(_messageToMap(message));
            }
          });
          _scrollToBottom();
        }
      });
      
      // Listen for typing indicators
      _typingSubscription = _webSocketService!.typingStream.listen((data) {
        if (mounted) {
          final userId = data['user_id'] ?? data['receiver_id'];
          final isTyping = data['is_typing'] == true;
          if (userId == widget.userId) {
            setState(() {
              _isOtherUserTyping = isTyping;
            });
          }
        }
      });
      
      // Listen for online status changes
      _onlineStatusSubscription = _webSocketService!.onlineStatusStream.listen((data) {
        if (mounted && data['user_id'] == widget.userId) {
          setState(() {
            _isOnline = data['is_online'] == true;
            if (!_isOnline) {
              _lastSeenAt = DateTime.now();
            }
          });
        }
      });
    } catch (e) {
      // WebSocket connection is optional - fail silently
      print('WebSocket initialization failed: $e');
    }
  }

  void _onTypingChanged(String text) {
    if (_webSocketService == null || !_webSocketService!.isConnected) return;
    
    // Cancel previous timer
    _typingTimer?.cancel();
    
    if (text.trim().isNotEmpty) {
      // Send typing started
      _webSocketService!.sendTypingStatus(widget.userId, true);
      
      // Set timer to stop typing after 3 seconds of inactivity
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _webSocketService?.sendTypingStatus(widget.userId, false);
      });
    } else {
      // Send typing stopped immediately
      _webSocketService!.sendTypingStatus(widget.userId, false);
    }
  }

  Future<void> _loadMessages() async {
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

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final messages = await chatService.getChatHistory(
        receiverId: widget.userId,
        page: 1,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          // Convert Message objects to Map format for MessageBubble
          _messages = messages.map((message) => _messageToMap(message)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
        
        // Mark messages as read
        _markAsRead();
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _messageToMap(Message message) {
    final isSent = _currentUserId != null
        ? message.senderId == _currentUserId
        : message.senderId != widget.userId;
    return {
      'id': message.id,
      'text': message.message,
      'is_sent': isSent,
      'sender_id': message.senderId,
      'timestamp': message.createdAt,
      'is_read': message.isRead,
      'type': message.messageType,
      'attachment_url': message.attachmentUrl,
      'is_locked': message.isLocked,
    };
  }

  Future<void> _markAsRead() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.markAsRead(widget.userId);
    } catch (e) {
      // Silently fail - marking as read is not critical
    }
  }

  Future<int> _getPinnedMessagesCount() async {
    if (widget.userId <= 0) return 0;
    try {
      final chatService = ref.read(chatServiceProvider);
      final count = await chatService.getPinnedMessagesCount(widget.userId);
      return count;
    } catch (e) {
      // Return 0 on error - pinned count is not critical
      return 0;
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

  Future<void> _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    // Optimistically add message to UI
    final tempMessageId = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _messages.add({
        'id': tempMessageId,
        'text': text,
        'is_sent': true,
        'timestamp': DateTime.now(),
        'is_read': false,
        'type': 'text',
        'replied_to': _repliedToMessage,
        'is_sending': true,
      });
      _repliedToMessage = null;
      _repliedToName = null;
      _repliedToMessageType = null;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final chatService = ref.read(chatServiceProvider);
      final sentMessage = await chatService.sendMessage(
        widget.userId,
        text,
        messageType: 'text',
      );

      if (mounted) {
        setState(() {
          // Remove temp message and add real one
          _messages.removeWhere((msg) => msg['id'] == tempMessageId);
          _messages.add(_messageToMap(sentMessage));
        });
        _scrollToBottom();
      }
           } on ApiError catch (e) {
             if (mounted) {
               // Remove failed message
               setState(() {
                 _messages.removeWhere((msg) => msg['id'] == tempMessageId);
               });
               ErrorHandlerService.showErrorSnackBar(
                 context,
                 e,
                 onRetry: () => _handleSend(text),
               );
             }
           } catch (e) {
             if (mounted) {
               // Remove failed message
               setState(() {
                 _messages.removeWhere((msg) => msg['id'] == tempMessageId);
               });
               ErrorHandlerService.handleError(
                 context,
                 e,
                 customMessage: 'Failed to send message',
                 onRetry: () => _handleSend(text),
               );
             }
    }
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
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Send photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(ImageSource.gallery, 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Send video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(ImageSource.gallery, 'video');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndSendMedia(ImageSource source, String type) async {
    int? tempId;
    try {
      final picker = ImagePicker();
      final file = type == 'video'
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source);
      if (file == null || !mounted) return;

      tempId = DateTime.now().millisecondsSinceEpoch;
      final now = DateTime.now();
      setState(() {
        _messages.add({
          'id': tempId,
          'text': type == 'video' ? 'Sending video...' : 'Sending image...',
          'is_sent': true,
          'sender_id': _currentUserId,
          'timestamp': now,
          'is_read': false,
          'type': type,
          'attachment_url': file.path,
          'is_sending': true,
        });
      });
      _scrollToBottom();

      final sent = await ref.read(chatServiceProvider).sendMessage(
            widget.userId,
            '',
            messageType: type,
            mediaFile: File(file.path),
          );
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
        _messages.add(_messageToMap(sent));
      });
      _scrollToBottom();
    } on ApiError catch (e) {
      if (!mounted) return;
      if (tempId != null) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
        });
      }
      ErrorHandlerService.showErrorSnackBar(
        context,
        e,
        customMessage: 'Failed to send media',
      );
    } catch (e) {
      if (!mounted) return;
      if (tempId != null) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
        });
      }
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to send media',
      );
    }
  }

  void _handleEmojiTap() {
    // Open emoji picker - implementation needed
    // This would typically show an emoji picker widget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emoji picker functionality will be implemented'),
      ),
    );
  }

  static const String _chatBgLight = 'assets/images/chat/chat-light.png';
  static const String _chatBgDark = 'assets/images/chat/chat-dark.png';

  Future<void> _handleVideoCallTap() async {
    final guard = PlanGuard(ref.read(planLimitsServiceProvider));
    final access = await guard.canMakeVideoCall();
    if (!mounted) return;
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
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          userId: widget.userId,
          userName: widget.userName ?? 'User',
          userAvatarUrl: widget.avatarUrl,
          isIncoming: false,
        ),
      ),
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
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ChatHeader(
          userId: widget.userId,
          name: widget.userName ?? 'User',
          avatarUrl: widget.avatarUrl,
          isOnline: _isOnline,
          lastSeenAt: _lastSeenAt,
          onBack: () => Navigator.of(context).pop(),
          onInfo: () {
            // Navigate to profile
            final target = Uri(
              path: AppRoutes.profileDetail,
              queryParameters: {'userId': widget.userId.toString()},
            ).toString();
            context.push(target);
          },
          onCall: () {
            // Navigate to voice call screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoiceCallScreen(
                  userId: widget.userId,
                  userName: widget.userName ?? 'User',
                  userAvatarUrl: widget.avatarUrl,
                  isIncoming: false,
                ),
              ),
            );
          },
          onVideoCall: () {
            _handleVideoCallTap();
          },
        ),
      ),
      body: Stack(
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
          // Pinned messages banner
          FutureBuilder<int>(
            future: _getPinnedMessagesCount(),
            builder: (context, snapshot) {
              final pinnedCount = snapshot.data ?? 0;
              if (pinnedCount == 0) {
                return const SizedBox.shrink();
              }
              return PinnedMessagesBanner(
                pinnedCount: pinnedCount,
                onTap: () {
                  _showPinnedMessages();
                },
              );
            },
          ),
          // Messages list
          Expanded(
            child: _isLoading
                ? SkeletonChat()
                : _hasError
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage ?? 'Failed to load messages',
                        onRetry: _loadMessages,
                      )
                    : _messages.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadMessages,
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
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _loadMessages,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final message = _messages[index];
                                      return MessageBubble(
                                        message: message['text'] ?? '',
                                        isSent: message['is_sent'] ?? false,
                                        timestamp: message['timestamp'],
                                        isRead: message['is_read'] ?? false,
                                        messageType: message['type'] ?? 'text',
                                        remainingSeconds: message['remaining_seconds'],
                                        mediaUrl: message['attachment_url']?.toString(),
                                        isLocked: message['is_locked'] == true,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Typing indicator
                              if (_isOtherUserTyping)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: TypingIndicator(),
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
            onEmojiTap: _handleEmojiTap,
            hintText: 'Type a message...',
            onTextChanged: _onTypingChanged,
          ),
            ],
          ),
        ],
      ),
    );
  }
}
