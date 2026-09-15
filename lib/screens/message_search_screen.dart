// Screen: MessageSearchScreen
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/providers/api_providers.dart';
import '../core/widgets/app_list_view.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/widgets/debounced_search_field.dart';
import '../core/providers/subscription_provider.dart';
import '../widgets/chat/chat_list_item.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/app_logger.dart';
import '../features/chat/data/local/chat_database_provider.dart';
import '../features/chat/utils/chat_message_search.dart';
import '../pages/chat_page.dart';

/// Message search screen - Search messages
class MessageSearchScreen extends ConsumerStatefulWidget {
  final int? conversationId;
  final String? initialQuery;

  const MessageSearchScreen({
    super.key,
    this.conversationId,
    this.initialQuery,
  });

  @override
  ConsumerState<MessageSearchScreen> createState() =>
      _MessageSearchScreenState();
}

class _MessageSearchScreenState extends ConsumerState<MessageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _offset = 0;
  int _searchEpoch = 0;
  List<ChatMessageSearchHit> _hits = [];
  List<Map<String, dynamic>> _recentSearches = [];
  SharedPreferences? _prefs;
  static const String _recentSearchesKey = 'message_recent_searches';
  static const int _maxRecentSearches = 10;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _searchController.text = initial;
      if (initial.length >= 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_performSearch(initial));
        });
      }
    }
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadRecentSearches();
    } catch (e) {
      AppLogger.warning(
        'Failed to initialize SharedPreferences',
        tag: 'Chat',
        error: e,
      );
      setState(() {
        _recentSearches = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onDebouncedQuery(String raw) {
    final query = raw.trim();
    if (query.isEmpty) {
      setState(() {
        _hits = [];
        _isLoading = false;
        _loadingMore = false;
        _hasMore = false;
        _offset = 0;
      });
      return;
    }
    if (query.length < 2) return;
    unawaited(_performSearch(query));
  }

  Future<void> _performSearch(String query, {bool loadMore = false}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    if (loadMore && (_loadingMore || !_hasMore || _isLoading)) return;

    final epoch = loadMore ? _searchEpoch : ++_searchEpoch;
    final repo = ref.read(chatLocalRepositoryProvider);

    if (loadMore) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _isLoading = _hits.isEmpty;
        _offset = 0;
        _hasMore = false;
      });
    }

    int? peerId;
    final conversationId = widget.conversationId;
    if (conversationId != null && conversationId > 0) {
      peerId = await repo.otherUserIdForConversation(conversationId) ??
          conversationId;
    }

    if (!loadMore) {
      try {
        final localHits = await repo.searchMessagesLocal(
          query: trimmed,
          otherUserId: peerId,
        );
        if (!mounted || epoch != _searchEpoch) return;
        setState(() {
          _hits = groupMessageSearchHits(localHits);
          _isLoading = _hits.isEmpty;
        });
      } catch (e) {
        AppLogger.warning(
          'Local message search failed',
          tag: 'Chat',
          error: e,
        );
      }
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      final offset = loadMore ? _offset : 0;
      final response = await apiService.get<Map<String, dynamic>>(
        ApiEndpoints.chatSearch,
        queryParameters: {
          'query': trimmed,
          'limit': 20,
          'offset': offset,
          if (widget.conversationId != null)
            'conversation_id': widget.conversationId,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!mounted || epoch != _searchEpoch) return;

      if (response.isSuccess && response.data != null) {
        final payload = response.data!;
        final data = payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload;
        final messages = data['messages'] as List<dynamic>? ?? [];
        final remoteHits = <ChatMessageSearchHit>[];
        for (final message in messages) {
          if (message is! Map) continue;
          final hit = chatMessageSearchHitFromApi(
            Map<String, dynamic>.from(message),
          );
          if (hit != null) remoteHits.add(hit);
        }

        setState(() {
          _hits = groupMessageSearchHits([..._hits, ...remoteHits]);
          _offset = offset + messages.length;
          _hasMore = messageSearchPageHasMore(messages.length);
          _isLoading = false;
          _loadingMore = false;
        });

        if (!loadMore) await _saveRecentSearch(trimmed);
      } else {
        setState(() {
          if (!loadMore && _hits.isEmpty) _hits = [];
          _isLoading = false;
          _loadingMore = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      AppLogger.warning(
        'Message search failed',
        tag: 'Chat',
        error: e,
      );
      if (!mounted || epoch != _searchEpoch) return;
      setState(() {
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    if (_prefs == null) {
      setState(() {
        _recentSearches = [];
      });
      return;
    }

    try {
      final searches = _prefs!.getStringList(_recentSearchesKey) ?? [];
      setState(() {
        _recentSearches = searches.map((search) => {'query': search}).toList();
      });
    } catch (e) {
      AppLogger.warning(
        'Failed to load recent searches',
        tag: 'Chat',
        error: e,
      );
      setState(() {
        _recentSearches = [];
      });
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty || _prefs == null) return;

    try {
      final searches = _prefs!.getStringList(_recentSearchesKey) ?? [];
      searches.remove(query);
      searches.insert(0, query);

      if (searches.length > _maxRecentSearches) {
        searches.removeRange(_maxRecentSearches, searches.length);
      }

      await _prefs!.setStringList(_recentSearchesKey, searches);
      _loadRecentSearches();
    } catch (e) {
      AppLogger.warning(
        'Failed to save recent search',
        tag: 'Chat',
        error: e,
      );
    }
  }

  Future<void> _removeRecentSearch(String query) async {
    if (_prefs == null) return;

    try {
      final searches = _prefs!.getStringList(_recentSearchesKey) ?? [];
      searches.remove(query);
      await _prefs!.setStringList(_recentSearchesKey, searches);
      _loadRecentSearches();
    } catch (e) {
      AppLogger.warning(
        'Failed to remove recent search',
        tag: 'Chat',
        error: e,
      );
    }
  }

  Future<void> _clearRecentSearches() async {
    if (_prefs == null) {
      setState(() {
        _recentSearches = [];
      });
      return;
    }

    try {
      await _prefs!.remove(_recentSearchesKey);
      _loadRecentSearches();
    } catch (e) {
      AppLogger.warning(
        'Failed to clear recent searches',
        tag: 'Chat',
        error: e,
      );
      setState(() {
        _recentSearches = [];
      });
    }
  }

  void _handleChatTap(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(userId: userId),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hits = [];
      _hasMore = false;
      _offset = 0;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final hasPlan = ref.watch(isPremiumProvider);

    return PremiumDetailScaffold(
      title: 'Search Messages',
      subtitle: 'Find conversations by keyword',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PremiumPageHeader.horizontalPadding,
              AppSpacing.spacingSM,
              PremiumPageHeader.horizontalPadding,
              AppSpacing.spacingSM,
            ),
            child: PremiumShell(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingXS,
              ),
              child: Row(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.search,
                    size: 20,
                    color: AppColors.accentViolet,
                  ),
                  const SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: DebouncedSearchField(
                      controller: _searchController,
                      autofocus: true,
                      showDefaultPrefix: false,
                      showClearButton: false,
                      hintText: 'Search conversations...',
                      style: AppTypography.body.copyWith(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: AppTypography.body
                            .copyWith(color: secondaryTextColor),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacingSM,
                        ),
                      ),
                      onChanged: _onDebouncedQuery,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return PremiumTapScale(
                        onTap: _clearSearch,
                        semanticLabel: 'Clear search',
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.spacingXS),
                          child: AppSvgIcon(
                            assetPath: AppIcons.close,
                            size: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading && _hits.isEmpty
                ? AppListView.builder(
                    physics: AppScroll.bouncing,
                    itemCount: 5,
                    padding: const EdgeInsets.all(AppSpacing.spacingLG),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: AppSpacing.spacingMD,
                        ),
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 80,
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                        ),
                      );
                    },
                  )
                : _searchController.text.isEmpty
                    ? _recentSearches.isEmpty
                        ? EmptyState(
                            title: 'Search Messages',
                            message:
                                'Enter a name or keyword to search your conversations',
                            iconPath: AppIcons.search,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  PremiumPageHeader.horizontalPadding,
                                  AppSpacing.spacingSM,
                                  PremiumPageHeader.horizontalPadding,
                                  AppSpacing.spacingSM,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Recent Searches',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _clearRecentSearches,
                                      child: Text(
                                        'Clear All',
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.accentViolet,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: AppListView.builder(
                                  physics: AppScroll.bouncing,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        PremiumPageHeader.horizontalPadding,
                                  ),
                                  itemCount: _recentSearches.length,
                                  itemBuilder: (context, index) {
                                    final search = _recentSearches[index];
                                    return RepaintBoundary(
                                      child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.spacingSM,
                                      ),
                                      child: PremiumShell(
                                        margin: EdgeInsets.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.spacingMD,
                                          vertical: AppSpacing.spacingSM,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            _searchController.text =
                                                search['query'];
                                            _performSearch(search['query']);
                                          },
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.radiusMD,
                                          ),
                                          child: Row(
                                            children: [
                                              AppSvgIcon(
                                                assetPath: AppIcons.search,
                                                size: 18,
                                                color: secondaryTextColor,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.spacingMD,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  search['query'],
                                                  style: AppTypography.body
                                                      .copyWith(color: textColor),
                                                ),
                                              ),
                                              PremiumTapScale(
                                                onTap: () => _removeRecentSearch(
                                                  search['query'],
                                                ),
                                                semanticLabel: 'Remove search',
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(
                                                    AppSpacing.spacingXS,
                                                  ),
                                                  child: AppSvgIcon(
                                                    assetPath: AppIcons.close,
                                                    size: 16,
                                                    color: secondaryTextColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                    : _hits.isEmpty
                        ? EmptyState(
                            title: 'No Results',
                            message: 'Try a different search term',
                            iconPath: AppIcons.searchZoomOut,
                          )
                        : AppListView.builder(
                            physics: AppScroll.bouncing,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.spacingSM,
                            ),
                            itemCount: _hits.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _hits.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.spacingMD,
                                  ),
                                  child: Center(
                                    child: _loadingMore
                                        ? const CircularProgressIndicator()
                                        : TextButton(
                                            onPressed: () => _performSearch(
                                              _searchController.text,
                                              loadMore: true,
                                            ),
                                            child: const Text('Load more'),
                                          ),
                                  ),
                                );
                              }
                              final result = _hits[index];
                              return RepaintBoundary(
                                child: ChatListItem(
                                  userId: result.otherUserId,
                                  name: result.name,
                                  avatarUrl: result.avatarUrl,
                                  lastMessage: result.preview,
                                  lastMessageTime: result.createdAt,
                                  unreadCount: 0,
                                  isOnline: false,
                                  hasPlan: hasPlan,
                                  onTap: () => _handleChatTap(result.otherUserId),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
