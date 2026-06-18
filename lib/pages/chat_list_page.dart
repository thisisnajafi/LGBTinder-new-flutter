// Screen: ChatListPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/common/selection_bottom_sheet.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_page_header.dart';
import '../widgets/chat/chat_matches_row.dart';
import '../features/matching/data/models/match.dart';
import '../features/matching/providers/likes_providers.dart';
import '../features/chat/presentation/widgets/chat_upgrade_widgets.dart';
import '../widgets/chat/chat_list_item.dart';
import '../widgets/chat/chat_list_loading.dart';
import '../widgets/chat/chat_list_empty.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../features/chat/providers/conversation_mute_cache_provider.dart';
import '../features/chat/providers/chat_provider.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/chat/providers/chat_typing_providers.dart';
import '../features/chat/providers/chat_list_preview_provider.dart';
import '../features/chat/data/models/chat.dart';
import '../features/chat/utils/chat_message_preview.dart';
import '../shared/models/api_error.dart';
import '../shared/models/user_tier.dart';
import '../shared/providers/user_tier_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/staggered_list_item.dart';
import '../routes/app_router.dart';

enum _ChatFilter { all, unread, online }

/// Chat list page - Displays list of conversations
class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({
    super.key,
    this.selectedTabIndex,
    this.messengerTabIndex,
  });

  /// When embedded in [HomePage], reload when user opens the Messenger tab.
  final int? selectedTabIndex;
  final int? messengerTabIndex;

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _searchQuery = '';
  List<Map<String, dynamic>> _chats = [];
  List<Match> _matches = [];
  bool _didInitialLoadAnimation = false;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  _ChatFilter _activeFilter = _ChatFilter.all;
  bool _premiumBannerDismissed = false;
  bool _retriedForMissingNames = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumBannerDismissed();
    _loadChats();
    _loadMatches();
  }

  @override
  void didUpdateWidget(ChatListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nowSelected = widget.selectedTabIndex != null &&
        widget.messengerTabIndex != null &&
        widget.selectedTabIndex == widget.messengerTabIndex;
    final wasSelected = oldWidget.selectedTabIndex != null &&
        oldWidget.messengerTabIndex != null &&
        oldWidget.selectedTabIndex == oldWidget.messengerTabIndex;
    if (nowSelected && !wasSelected) {
      _loadChats(forceRefresh: true);
      _loadMatches();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await ref.read(likesServiceProvider).getMatches();
      if (mounted) {
        setState(() => _matches = matches);
      }
    } catch (_) {
      // Non-blocking — matches row hides when empty.
    }
  }

  Future<void> _loadPremiumBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _premiumBannerDismissed =
            prefs.getBool('chat_premium_banner_dismissed') ?? false;
      });
    }
  }

  Future<void> _dismissPremiumBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_premium_banner_dismissed', true);
    if (mounted) setState(() => _premiumBannerDismissed = true);
  }

  Future<void> _loadChats({bool forceRefresh = false}) async {
    var showedCache = false;

    if (!forceRefresh) {
      try {
        final cached =
            await ref.read(chatLocalRepositoryProvider).getConversations();
        if (cached.isNotEmpty && mounted) {
          showedCache = true;
          ref.read(conversationMuteCacheProvider.notifier).seedFromChats(cached);
          final maps = cached.map((chat) => _chatToMap(chat)).toList();
          ref.read(chatListPreviewProvider.notifier).seedFromMaps(maps);
          setState(() {
            _chats = maps;
            _isLoading = false;
            _hasError = false;
            _errorMessage = null;
          });
        }
      } catch (_) {
        // Non-blocking — fall through to network.
      }
    }

    if (!showedCache) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final chatService = ref.read(chatServiceProvider);
      var chats = await chatService.getChatUsers(forceRefresh: forceRefresh);

      if (!_retriedForMissingNames &&
          !forceRefresh &&
          chats.isNotEmpty &&
          chats.every((chat) => chat.displayName == 'User')) {
        _retriedForMissingNames = true;
        chats = await chatService.getChatUsers(forceRefresh: true);
      }

      if (mounted) {
        await ref
            .read(chatLocalRepositoryProvider)
            .replaceAllConversations(chats);
        ref.read(conversationMuteCacheProvider.notifier).seedFromChats(chats);
        final maps = chats.map((chat) => _chatToMap(chat)).toList();
        ref.read(chatListPreviewProvider.notifier).seedFromMaps(maps);
        setState(() {
          _chats = maps;
          _isLoading = false;
          _hasError = false;
        });
        Future.delayed(
          const Duration(milliseconds: 800),
          () {
            if (mounted) setState(() => _didInitialLoadAnimation = true);
          },
        );
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

  String _displayNameFromMap(Map<String, dynamic> chat) {
    final name = chat['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final first = chat['first_name']?.toString().trim() ?? '';
    final last = chat['last_name']?.toString().trim() ?? '';
    if (first.isNotEmpty) {
      return last.isNotEmpty ? '$first $last' : first;
    }
    return 'User';
  }

  Map<String, dynamic> _chatToMap(Chat chat) {
    return {
      'id': chat.userId, // Use userId for navigation to chat
      'chat_id': chat.id, // Keep chat id for reference
      'name': chat.displayName,
      'first_name': chat.firstName,
      'last_name': chat.lastName,
      'avatar_url': chat.primaryImageUrl,
      'last_message': chatMessagePreviewText(
        message: chat.lastMessage?.message,
        messageType: chat.lastMessage?.messageType,
        mediaDuration: chat.lastMessage?.mediaDuration,
      ),
      'last_message_type': chat.lastMessage?.messageType,
      'last_message_time': chat.lastMessageAt ?? chat.lastMessage?.createdAt,
      'unread_count': chat.unreadCount,
      'is_online': chat.isOnline,
      'is_typing': chat.isTyping,
      'is_muted': chat.isMuted,
    };
  }

  List<Map<String, dynamic>> get _filteredChats {
    final source = ref.watch(chatListPreviewProvider).isSeeded
        ? ref.watch(chatListPreviewProvider).items.map((e) => e.toMap()).toList()
        : _chats;

    final base = source.where((chat) {
      switch (_activeFilter) {
        case _ChatFilter.unread:
          return (chat['unread_count'] as int? ?? 0) > 0;
        case _ChatFilter.online:
          return chat['is_online'] == true;
        case _ChatFilter.all:
          return true;
      }
    }).toList();

    if (_searchQuery.isEmpty) {
      return base;
    }
    return base
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

  Future<void> _openFilterSheet() async {
    final selected = await SelectionBottomSheet.showSingleSelect<_ChatFilter>(
      context: context,
      title: 'Filter chats',
      items: _ChatFilter.values,
      getTitle: (filter) => switch (filter) {
        _ChatFilter.all => 'All chats',
        _ChatFilter.unread => 'Unread only',
        _ChatFilter.online => 'Online only',
      },
      selectedItem: _activeFilter,
    );
    if (selected != null) {
      setState(() => _activeFilter = selected);
    }
  }

  void _handleChatTap(Map<String, dynamic> chat) {
    final userTier = ref.read(userTierProvider);
    if (userTier == UserTier.basid) {
      ChatUpgradeBottomSheet.show(context);
      return;
    }

    final userId = chat['id'] as int? ?? 0;
    if (userId <= 0) return;

    final target = Uri(
      path: AppRoutes.chat,
      queryParameters: {
        'userId': userId.toString(),
        if (_displayNameFromMap(chat) != 'User')
          'userName': _displayNameFromMap(chat),
        if ((chat['avatar_url'] as String?)?.isNotEmpty == true)
          'avatarUrl': chat['avatar_url'] as String,
      },
    ).toString();
    context.push(target);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(chatTypingSyncProvider);
    ref.watch(chatListSyncProvider);
    final typingUsers = ref.watch(
      chatProvider.select((state) => state.typingUsers),
    );

    final theme = Theme.of(context);
    final tier = ref.watch(userTierProvider);
    final showPremiumBanner =
        tier == UserTier.basid && !_premiumBannerDismissed;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Messenger',
              action: IconButton(
                icon: AppSvgIcon(
                  assetPath: AppIcons.search,
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() => _showSearch = !_showSearch);
                },
              ),
            ),
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppPageHeader.horizontalPadding,
                  AppSpacing.spacingSM,
                  AppPageHeader.horizontalPadding,
                  0,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: AppSvgIcon(
                      assetPath: AppIcons.search,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingSM,
                    ),
                  ),
                ),
              ),
            ChatMatchesRow(matches: _matches),
            const SizedBox(height: AppSpacing.spacingLG),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPageHeader.horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Messages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  IconButton(
                    icon: AppSvgIcon(
                      assetPath: AppIcons.sort,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: _openFilterSheet,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ],
              ),
            ),
            if (showPremiumBanner)
              ChatPremiumBanner(
                onDismiss: _dismissPremiumBanner,
                onUpgrade: () => context.push(AppRoutes.subscriptionPlans),
              ),
            Expanded(
              child: _isLoading && _chats.isEmpty
                  ? const ChatListLoading(itemCount: 5)
                  : _hasError && _chats.isEmpty
                      ? ErrorDisplayWidget(
                          errorMessage:
                              _errorMessage ?? 'Failed to load conversations',
                          onRetry: _loadChats,
                        )
                      : _filteredChats.isEmpty
                          ? RefreshIndicator(
                              onRefresh: () async {
                                await _loadChats(forceRefresh: true);
                                await _loadMatches();
                              },
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  child: const ChatListEmpty(),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await _loadChats(forceRefresh: true);
                                await _loadMatches();
                              },
                              child: ListView.separated(
                                itemCount: _filteredChats.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.spacingXS),
                                itemBuilder: (context, index) {
                                  final chat = _filteredChats[index];
                                  final userId = chat['id'] as int;
                                  final isTypingLive =
                                      typingUsers[userId] == true;
                                  final item = ChatListItem(
                                    userId: userId,
                                    name: _displayNameFromMap(chat),
                                    avatarUrl: chat['avatar_url'],
                                    lastMessage: chat['last_message'],
                                    lastMessageType:
                                        chat['last_message_type']?.toString(),
                                    lastMessageTime: chat['last_message_time'],
                                    unreadCount: chat['unread_count'],
                                    isOnline: chat['is_online'],
                                    isTyping: chat['is_typing'] == true ||
                                        isTypingLive,
                                    isMuted: chat['is_muted'] == true,
                                    onTap: () => _handleChatTap(chat),
                                  );
                                  return StaggeredListItem(
                                    index: index,
                                    animateAppear:
                                        !_didInitialLoadAnimation && index < 8,
                                    child: item,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
