// Screen: ChatListPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/chat/chat_list_header.dart';
import '../widgets/chat/chat_list_item.dart';
import '../widgets/chat/chat_list_loading.dart';
import '../widgets/chat/chat_list_empty.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/chat/data/models/chat.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../shared/models/api_error.dart';
import '../pages/chat_page.dart';
import 'package:go_router/go_router.dart';

/// Chat list page - Displays list of conversations
class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _searchQuery = '';
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final chats = await chatService.getChatUsers();

      if (mounted) {
        setState(() {
          // Convert Chat objects to Map format for ChatListItem
          _chats = chats.map((chat) => _chatToMap(chat)).toList();
          _isLoading = false;
        });
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

  Map<String, dynamic> _chatToMap(Chat chat) {
    return {
      'id': chat.userId, // Use userId for navigation to chat
      'chat_id': chat.id, // Keep chat id for reference
      'name': chat.lastName != null
          ? '${chat.firstName} ${chat.lastName}'
          : chat.firstName,
      'avatar_url': chat.primaryImageUrl,
      'last_message': chat.lastMessage?.message ?? '',
      'last_message_time': chat.lastMessageAt ?? chat.lastMessage?.createdAt,
      'unread_count': chat.unreadCount,
      'is_online': chat.isOnline,
      'is_typing': chat.isTyping,
    };
  }

  List<Map<String, dynamic>> get _filteredChats {
    if (_searchQuery.isEmpty) {
      return _chats;
    }
    return _chats
        .where((chat) =>
            chat['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            chat['last_message']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _handleChatTap(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Messages',
        showBackButton: false,
        notificationCount: ref.watch(unreadNotificationCountProvider).when(
              data: (count) => count,
              loading: () => null,
              error: (_, __) => null,
            ),
        onNotificationTap: () {
          context.go('/home/notifications');
        },
      ),
      body: Column(
        children: [
          ChatListHeader(
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            onFilterTap: () {
              // TODO: Open filters
            },
          ),
          Expanded(
            child: _isLoading
                ? const ChatListLoading(itemCount: 5)
                : _hasError
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage ?? 'Failed to load conversations',
                        onRetry: _loadChats,
                      )
                    : _filteredChats.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadChats,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: const ChatListEmpty(),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadChats,
                            child: ListView.builder(
                              itemCount: _filteredChats.length,
                              itemBuilder: (context, index) {
                                final chat = _filteredChats[index];
                                return ChatListItem(
                                  userId: chat['id'],
                                  name: chat['name'],
                                  avatarUrl: chat['avatar_url'],
                                  lastMessage: chat['last_message'],
                                  lastMessageTime: chat['last_message_time'],
                                  unreadCount: chat['unread_count'],
                                  isOnline: chat['is_online'],
                                  isTyping: chat['is_typing'],
                                  onTap: () => _handleChatTap(chat['id']),
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
