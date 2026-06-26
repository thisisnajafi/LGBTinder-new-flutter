// Screen: ChatListPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
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
import '../core/providers/subscription_provider.dart';
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

  void _handleChatTap(Map<String, dynamic> chat) {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
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
    final showPremiumBanner =
        !ref.watch(isPremiumProvider) && !_premiumBannerDismissed;

    return PremiumTabPageLayout(
      title: 'Messenger',
      subtitle: 'Your conversations & matches',
      action: IconButton(
        icon: AppSvgIcon(
          assetPath: AppIcons.search,
          size: 24,
          color: theme.colorScheme.onSurface,
        ),
        onPressed: () => setState(() => _showSearch = !_showSearch),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PremiumPageHeader.horizontalPadding,
                0,
                PremiumPageHeader.horizontalPadding,
                AppSpacing.spacingSM,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: _MessengerSearchPrefixIcon(isDark: theme.brightness == Brightness.dark),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 52,
                    minHeight: 44,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    borderSide: BorderSide(
                      color: AppColors.accentViolet.withValues(alpha: 0.14),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    borderSide: BorderSide(
                      color: AppColors.accentViolet.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingSM,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
            child: PremiumCategoryChips(
              labels: const ['All', 'Unread', 'Online'],
              selectedIndex: _activeFilter.index,
              onSelected: (i) =>
                  setState(() => _activeFilter = _ChatFilter.values[i]),
            ),
          ),
          ChatMatchesRow(matches: _matches),
          const SizedBox(height: AppSpacing.spacingMD),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: PremiumPageHeader.horizontalPadding,
                              ),
                              itemCount: _filteredChats.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.spacingSM),
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
    );
  }
}

/// Gradient search badge for the messenger search field prefix.
class _MessengerSearchPrefixIcon extends StatelessWidget {
  const _MessengerSearchPrefixIcon({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.spacingSM),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentViolet.withValues(alpha: isDark ? 0.32 : 0.16),
              AppColors.accentPink.withValues(alpha: isDark ? 0.24 : 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentViolet.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accentViolet, AppColors.accentPink],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: AppSvgIcon(
            assetPath: AppIcons.getIconBold('search-normal'),
            size: 17,
          ),
        ),
      ),
    );
  }
}
