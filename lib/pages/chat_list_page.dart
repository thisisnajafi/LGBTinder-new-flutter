// Screen: ChatListPage
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/responsive/responsive.dart';
import '../core/utils/app_haptics.dart';
import '../core/utils/app_icons.dart';
import '../core/services/app_logger.dart';
import '../core/constants/animation_constants.dart';
import '../core/utils/media_url.dart';
import '../core/cache/peer_avatar_cache.dart';
import '../core/widgets/app_action_bottom_sheet.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/chat/chat_connection_banner.dart';
import '../widgets/chat/chat_matches_row.dart';
import '../features/matching/data/models/match.dart';
import '../features/matching/providers/likes_providers.dart';
import '../features/chat/presentation/widgets/chat_upgrade_widgets.dart';
import '../widgets/chat/chat_list_item.dart';
import '../widgets/chat/chat_list_loading.dart';
import '../widgets/chat/chat_list_empty.dart';
import '../widgets/chat/chat_list_reorder_row.dart';
import '../widgets/chat/chat_list_search_field.dart';
import '../widgets/chat/chat_list_swipe_row.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../widgets/modals/confirmation_dialog.dart';
import '../features/chat/providers/conversation_mute_cache_provider.dart';
import '../features/chat/providers/conversation_pin_cache_provider.dart';
import '../features/chat/providers/chat_list_hidden_peers_provider.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/chat/providers/chat_list_preview_provider.dart';
import '../features/chat/providers/user_presence_cache_provider.dart';
import '../features/chat/utils/chat_list_filter.dart';
import '../features/calls/presentation/widgets/messenger_calls_list.dart';
import '../features/calls/providers/messenger_calls_provider.dart';
import '../features/calls/utils/messenger_call_groups.dart';
import '../shared/models/api_error.dart';
import '../core/providers/subscription_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_router.dart';
import '../routes/home_tab_routes.dart';
import 'chat_page.dart';
import '../screens/message_search_screen.dart';

enum _MessengerSection { chats, calls }

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
  List<Match> _matches = [];
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  ChatListRowFilter _activeFilter = ChatListRowFilter.all;
  _MessengerSection _section = _MessengerSection.chats;
  MessengerCallFilter _callFilter = MessengerCallFilter.all;
  bool _premiumBannerDismissed = false;
  bool _retriedForMissingNames = false;
  int? _tabletSelectedUserId;
  String? _tabletSelectedUserName;
  String? _tabletSelectedAvatarUrl;

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
      if (_section == _MessengerSection.calls) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(messengerCallsProvider.notifier).refresh();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshMessenger() async {
    if (_section == _MessengerSection.calls) {
      await ref.read(messengerCallsProvider.notifier).refresh();
      return;
    }
    await _loadChats(forceRefresh: true);
    await _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await ref.read(likesServiceProvider).getMatches();
      unawaited(ref.read(peerAvatarCacheProvider.notifier).rememberMany({
        for (final match in matches)
          if (match.userId > 0) match.userId: match.primaryImageUrl,
      }));
      if (mounted) {
        setState(() => _matches = matches);
      }
    } catch (e) {
      AppLogger.warning(
        'Matches row load failed',
        tag: 'Chat',
        error: e,
      );
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
          ref.read(conversationPinCacheProvider.notifier).seedFromChats(cached);
          final items = await _hydratePreviewAvatars(
            cached.map(ChatListPreviewItem.fromChat).toList(),
          );
          if (!mounted) return;
          ref.read(chatListPreviewProvider.notifier).seedFromItems(items);
          setState(() {
            _isLoading = false;
            _hasError = false;
            _errorMessage = null;
          });
        }
      } catch (e) {
        AppLogger.warning(
          'Cached conversation list load failed; falling through to network',
          tag: 'Chat',
          error: e,
        );
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
        ref.read(conversationPinCacheProvider.notifier).seedFromChats(chats);
        final items = await _hydratePreviewAvatars(
          chats.map(ChatListPreviewItem.fromChat).toList(),
        );
        if (!mounted) return;
        ref.read(chatListPreviewProvider.notifier).seedFromItems(items);
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } on ApiError catch (e) {
      AppLogger.warning(
        'Conversation list refresh failed',
        tag: 'Chat',
        error: e,
      );
      if (mounted && !showedCache) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.warning(
        'Conversation list refresh failed',
        tag: 'Chat',
        error: e,
      );
      if (mounted && !showedCache) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<List<ChatListPreviewItem>> _hydratePreviewAvatars(
    List<ChatListPreviewItem> items,
  ) async {
    final cache = ref.read(peerAvatarCacheProvider.notifier);
    await cache.rememberMany({
      for (final item in items)
        if (item.id > 0) item.id: item.avatarUrl,
    });
    final cached = ref.read(peerAvatarCacheProvider);
    return [
      for (final item in items)
        item.copyWith(
          avatarUrl: MediaUrl.pick(
                userId: item.id,
                incoming: item.avatarUrl,
                cached: cached[item.id],
              ) ??
              item.avatarUrl,
        ),
    ];
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

  List<Map<String, dynamic>> _filteredChats(ChatListPreviewState preview) {
    final pinnedIds = ref.watch(conversationPinCacheProvider);
    final source = [
      for (final item in preview.items) item.toMap(),
    ];
    final withPins = [
      for (final chat in source)
        {
          ...chat,
          'is_pinned': pinnedIds.contains(chat['id'] as int? ?? 0) ||
              chat['is_pinned'] == true ||
              chat['is_pinned'] == 1,
        },
    ];

    return ChatListFilter.apply(
      source: withPins,
      filter: _activeFilter,
      query: _searchQuery,
      hiddenIds: ref.watch(chatListHiddenPeersProvider),
      presenceByUser: _activeFilter == ChatListRowFilter.online
          ? {
              for (final entry in ref.watch(userPresenceCacheProvider).entries)
                entry.key: entry.value.isOnline,
            }
          : const {},
    );
  }

  void _handleChatTap(Map<String, dynamic> chat) {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      ChatUpgradeBottomSheet.show(context);
      return;
    }

    final userId = chat['id'] as int? ?? 0;
    if (userId <= 0) return;

    if (AppBreakpoints.isTablet(context)) {
      setState(() {
        _tabletSelectedUserId = userId;
        _tabletSelectedUserName = _displayNameFromMap(chat);
        _tabletSelectedAvatarUrl = chat['avatar_url'] as String?;
      });
      return;
    }

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

  Future<void> _swipeMute(int userId, bool currentlyMuted) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final muted = currentlyMuted
          ? await chatService.unmuteConversation(userId)
          : await chatService.muteConversation(userId);
      ref.read(conversationMuteCacheProvider.notifier).setMuted(userId, muted);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(muted ? 'Conversation muted' : 'Conversation unmuted'),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, stack) {
      AppLogger.error(
        'Swipe mute failed',
        tag: 'ChatListPage',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update mute')),
      );
    }
  }

  Future<void> _togglePin(int userId, bool currentlyPinned) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final pinned = currentlyPinned
          ? await chatService.unpinConversation(userId)
          : await chatService.pinConversation(userId);
      ref.read(conversationPinCacheProvider.notifier).setPinned(userId, pinned);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pinned ? 'Conversation pinned' : 'Conversation unpinned'),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, stack) {
      AppLogger.error(
        'Conversation pin failed',
        tag: 'ChatListPage',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update pin')),
      );
    }
  }

  Future<void> _showConversationActions({
    required int userId,
    required String name,
    required bool pinned,
  }) async {
    AppHaptics.medium();
    await AppActionBottomSheet.show<void>(
      context: context,
      title: name == 'User' ? 'Conversation' : name,
      actions: [
        AppActionSheetItem(
          iconPath: pinned ? AppIcons.bookmark2 : AppIcons.bookmark,
          label: pinned ? 'Unpin' : 'Pin',
          subtitle: pinned
              ? 'Remove from the top of your list'
              : 'Keep this chat at the top of your list',
          onTap: () {
            Navigator.pop(context);
            unawaited(_togglePin(userId, pinned));
          },
        ),
      ],
    );
  }

  Future<bool> _confirmHideConversation(String name) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Delete conversation?',
      message: name == 'User'
          ? 'Remove this chat from your list? You can undo for a few seconds.'
          : 'Remove $name from your list? You can undo for a few seconds.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    return ok == true;
  }

  void _hideConversation(int userId, String name) {
    ref.read(chatListHiddenPeersProvider.notifier).hide(userId);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: AppAnimations.chatListDeleteUndo,
        content: Text(
          name == 'User' ? 'Conversation hidden' : '$name hidden',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(chatListHiddenPeersProvider.notifier).restore(userId);
          },
        ),
      ),
    );
  }

  void _openPeerChat({
    required int userId,
    required String name,
    String? avatarUrl,
  }) {
    _handleChatTap({
      'id': userId,
      'name': name,
      'avatar_url': avatarUrl,
      'unread_count': 0,
      'is_online': false,
    });
  }

  void _selectMessengerSection(_MessengerSection section) {
    if (_section == section) return;
    setState(() => _section = section);
  }

  void _clearTabletSelection() {
    setState(() {
      _tabletSelectedUserId = null;
      _tabletSelectedUserName = null;
      _tabletSelectedAvatarUrl = null;
    });
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _showSearch = false;
      _searchQuery = '';
    });
  }

  void _openMessageSearch(String value) {
    if (_section != _MessengerSection.chats) return;
    final query = value.trim();
    if (query.length < 2) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessageSearchScreen(initialQuery: query),
      ),
    );
  }

  void _toggleSearch() {
    if (_showSearch) {
      _closeSearch();
      return;
    }
    setState(() => _showSearch = true);
  }

  Widget _buildSearchField() {
    return ChatListSearchField(
      visible: _showSearch,
      controller: _searchController,
      hintText: _section == _MessengerSection.calls
          ? 'Search calls...'
          : 'Search conversations...',
      onChanged: (value) => setState(() => _searchQuery = value),
      onSubmitted: _openMessageSearch,
      onClose: _closeSearch,
    );
  }

  Widget _buildConversationList({
    required EdgeInsets listPadding,
  }) {
    final preview = ref.watch(chatListPreviewProvider);
    final filtered = _filteredChats(preview);
    final mutedIds = ref.watch(conversationMuteCacheProvider);
    final pinnedIds = ref.watch(conversationPinCacheProvider);
    final showLoading =
        _isLoading && !preview.isSeeded && filtered.isEmpty;
    final showError =
        _hasError && !preview.isSeeded && filtered.isEmpty;

    return Expanded(
      child: showLoading
          ? const ChatListLoading(itemCount: 5)
          : showError
              ? ErrorDisplayWidget(
                  errorMessage:
                      _errorMessage ?? 'Failed to load conversations',
                  onRetry: _loadChats,
                )
              : filtered.isEmpty
                  ? SingleChildScrollView(
                      physics: AppScroll.bouncing,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height *
                            (ChatListEmpty.showsDiscoverCta(_searchQuery)
                                ? 0.5
                                : 0.35),
                        child: ChatListEmpty(
                          title: ChatListEmpty.titleFor(_searchQuery),
                          message: ChatListEmpty.messageFor(_searchQuery),
                          iconPath: ChatListEmpty.isSearchQuery(_searchQuery)
                              ? AppIcons.search
                              : AppIcons.chatBubbleOutline,
                          onDiscover:
                              ChatListEmpty.showsDiscoverCta(_searchQuery)
                                  ? () => context.go(
                                        HomeTabRoutes.locationForTab(0),
                                      )
                                  : null,
                        ),
                      ),
                    )
                  : ChatListReorderList(
                      physics: AppScroll.forChat(context),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: listPadding,
                      itemCount: filtered.length,
                      itemIdAt: (index) => filtered[index]['id'] as int,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.spacingXS),
                      itemBuilder: (context, index) {
                        final chat = filtered[index];
                        final userId = chat['id'] as int;
                        final name = _displayNameFromMap(chat);
                        final muted = mutedIds.contains(userId) ||
                            chat['is_muted'] == true;
                        final pinned = pinnedIds.contains(userId) ||
                            chat['is_pinned'] == true ||
                            chat['is_pinned'] == 1;
                        final hasPlan = ref.watch(isPremiumProvider);
                        return ChatListSwipeRow(
                          userId: userId,
                          isMuted: muted,
                          isPinned: pinned,
                          onMuteToggle: () => _swipeMute(userId, muted),
                          onPinToggle: () => _togglePin(userId, pinned),
                          onConfirmDelete: () =>
                              _confirmHideConversation(name),
                          onDeleted: () => _hideConversation(userId, name),
                          child: RepaintBoundary(
                            child: ChatListItem(
                              userId: userId,
                              name: name,
                              avatarUrl: chat['avatar_url'],
                              lastMessage: chat['last_message'],
                              lastMessageType:
                                  chat['last_message_type']?.toString(),
                              lastMessageTime: chat['last_message_time'],
                              unreadCount: chat['unread_count'],
                              isOnline: chat['is_online'] == true ||
                                  chat['is_online'] == 1,
                              lastSeenAt: chat['last_seen'] is DateTime
                                  ? chat['last_seen'] as DateTime
                                  : DateTime.tryParse(
                                      chat['last_seen']?.toString() ??
                                          chat['last_seen_at']?.toString() ??
                                          '',
                                    ),
                              isTyping: chat['is_typing'] == true,
                              isMuted: muted,
                              isPinned: pinned,
                              lastMessageFromMe:
                                  chat['last_message_from_me'] == true,
                              lastMessageIsRead:
                                  chat['last_message_is_read'] == true,
                              lastMessageIsDelivered:
                                  chat['last_message_is_delivered'] == true,
                              highlightQuery: _searchQuery,
                              onTap: () => _handleChatTap(chat),
                              onLongPress: () => _showConversationActions(
                                userId: userId,
                                name: name,
                                pinned: pinned,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildMessengerBody({
    required ThemeData theme,
    required bool showPremiumBanner,
    EdgeInsets listPadding = const EdgeInsets.fromLTRB(
      PremiumPageHeader.horizontalPadding,
      AppSpacing.spacingXS,
      PremiumPageHeader.horizontalPadding,
      AppSpacing.spacingLG,
    ),
    bool compactHeader = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ChatConnectionBanner(),
        _buildSearchField(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PremiumPageHeader.horizontalPadding,
            0,
            PremiumPageHeader.horizontalPadding,
            AppSpacing.spacingSM,
          ),
          child: _MessengerSectionSwitch(
            selectedIndex: _section.index,
            onSelected: (i) =>
                _selectMessengerSection(_MessengerSection.values[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
          child: PremiumCategoryChips(
            labels: _section == _MessengerSection.calls
                ? const ['All', 'Missed', 'Incoming', 'Outgoing']
                : const ['All', 'Unread', 'Online'],
            selectedIndex: _section == _MessengerSection.calls
                ? _callFilter.index
                : _activeFilter.index,
            onSelected: (i) {
              setState(() {
                if (_section == _MessengerSection.calls) {
                  _callFilter = MessengerCallFilter.values[i];
                } else {
                  _activeFilter = ChatListRowFilter.values[i];
                }
              });
            },
          ),
        ),
        if (_section == _MessengerSection.chats)
          ChatMatchesRow(
            matches: _matches,
            onMatchTap: (match) => _openPeerChat(
              userId: match.userId,
              name: match.firstName,
              avatarUrl: match.primaryImageUrl,
            ),
          ),
        if (_section == _MessengerSection.chats &&
            showPremiumBanner &&
            !compactHeader)
          ChatPremiumBanner(
            onDismiss: _dismissPremiumBanner,
            onUpgrade: () => context.push(AppRoutes.subscriptionPlans),
          ),
        if (_section == _MessengerSection.calls)
          MessengerCallsList(
            filter: _callFilter,
            searchQuery: _searchQuery,
            listPadding: listPadding,
          )
        else
          _buildConversationList(
            listPadding: listPadding,
          ),
      ],
    );
  }

  Widget _buildTabletEmptyDetail(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ColoredBox(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Center(
        child: Padding(
          padding: ResponsivePadding.horizontal(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                assetPath: AppIcons.message,
                size: 48,
                color: muted,
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              AppText(
                'Select a conversation',
                style: theme.textTheme.titleMedium?.copyWith(color: muted),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletMasterDetail({
    required ThemeData theme,
    required bool showPremiumBanner,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark
        ? AppColors.borderMediumDark
        : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: ResponsiveGrid.chatMasterPanelWidth,
              child: PremiumRefreshScope(
                    onRefresh: _refreshMessenger,
                    header: PremiumPageHeader(
                      title: 'Messenger',
                      subtitle: _section == _MessengerSection.calls
                          ? 'Voice and video recents'
                          : 'Conversations',
                      action: IconButton(
                        icon: AppSvgIcon(
                          assetPath: AppIcons.search,
                          size: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                        tooltip: _showSearch ? 'Close search' : 'Search',
                        onPressed: _toggleSearch,
                      ),
                    ),
                    body: _buildMessengerBody(
                      theme: theme,
                      showPremiumBanner: showPremiumBanner,
                      listPadding: const EdgeInsets.fromLTRB(
                        AppSpacing.spacingSM,
                        AppSpacing.spacingXS,
                        AppSpacing.spacingSM,
                        AppSpacing.spacingLG,
                      ),
                      compactHeader: true,
                    ),
                  ),
            ),
            VerticalDivider(width: 1, color: dividerColor),
            Expanded(
              child: _tabletSelectedUserId != null
                  ? ChatPage(
                      key: ValueKey(_tabletSelectedUserId),
                      userId: _tabletSelectedUserId!,
                      userName: _tabletSelectedUserName,
                      avatarUrl: _tabletSelectedAvatarUrl,
                      embedded: true,
                      onEmbeddedClose: _clearTabletSelection,
                    )
                  : _buildTabletEmptyDetail(theme),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPremiumBanner =
        !ref.watch(isPremiumProvider) && !_premiumBannerDismissed;

    try {
      return ResponsiveLayout(
        phone: (_) => PremiumTabPageLayout(
          title: 'Messenger',
          subtitle: _section == _MessengerSection.calls
              ? 'Voice and video recents'
              : 'Your conversations & matches',
          onRefresh: _refreshMessenger,
          action: IconButton(
            icon: AppSvgIcon(
              assetPath: AppIcons.search,
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          body: _buildMessengerBody(
            theme: theme,
            showPremiumBanner: showPremiumBanner,
          ),
        ),
        tablet: (_) => _buildTabletMasterDetail(
          theme: theme,
          showPremiumBanner: showPremiumBanner,
        ),
      );
    } catch (error, stack) {
      AppLogger.error(
        'ChatListPage build failed',
        tag: 'ChatListPage',
        error: error,
        stackTrace: stack,
      );
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: ErrorDisplayWidget(
          title: 'Messenger unavailable',
          errorMessage:
              'This screen hit an unexpected error. Retry without leaving the app.',
          onRetry: () {
            if (mounted) setState(() {});
          },
        ),
      );
    }
  }
}

/// Chats | Calls switch at the top of Messenger.
class _MessengerSectionSwitch extends StatelessWidget {
  const _MessengerSectionSwitch({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Chats', 'Calls'];
    final theme = Theme.of(context);
    final track = theme.colorScheme.onSurface.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: PremiumTapScale(
                onTap: () => onSelected(i),
                semanticLabel: labels[i],
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: selectedIndex == i ? AppColors.brandGradient : null,
                  ),
                  child: Text(
                    labels[i],
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selectedIndex == i
                          ? Colors.white
                          : AppColors.accentViolet,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
