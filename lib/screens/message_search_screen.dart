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
import '../core/widgets/premium/premium_design_system.dart';
import '../core/widgets/debounced_search_field.dart';
import '../widgets/chat/chat_list_item.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/app_logger.dart';
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
  List<Map<String, dynamic>> _searchResults = [];
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
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }
    if (query.length < 2) return;
    unawaited(_performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<Map<String, dynamic>>(
        ApiEndpoints.chatSearch,
        queryParameters: {
          'query': query,
          'limit': 20,
          if (widget.conversationId != null)
            'conversation_id': widget.conversationId,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final payload = response.data!;
        final data = payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload;
        final messages = data['messages'] as List<dynamic>? ?? [];

        final groupedResults = <Map<String, dynamic>>[];
        final chatMap = <int, Map<String, dynamic>>{};

        for (final message in messages) {
          final messageData = message as Map<String, dynamic>;
          final otherUser = messageData['other_user'] as Map<String, dynamic>;
          final threadId = _threadIdFromSearchHit(messageData) ??
              (otherUser['id'] as num?)?.toInt();
          if (threadId == null) continue;

          if (!chatMap.containsKey(threadId)) {
            chatMap[threadId] = {
              'id': otherUser['id'],
              'name': otherUser['name'],
              'avatar_url': otherUser['avatar_url'],
              'last_message': messageData['message'],
              'last_message_time': DateTime.parse(messageData['created_at']),
              'unread_count': 0,
              'is_online': false,
              'is_verified': false,
              'is_premium': false,
              'conversation_id': threadId,
            };
            groupedResults.add(chatMap[threadId]!);
          }
        }

        setState(() {
          _searchResults = groupedResults;
          _isLoading = false;
        });

        await _saveRecentSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.warning(
        'Message search failed',
        tag: 'Chat',
        error: e,
      );
      setState(() {
        _isLoading = false;
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

  int? _threadIdFromSearchHit(Map<String, dynamic> messageData) {
    final raw = messageData['conversation_id'] ?? messageData['chat_id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
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
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

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
            child: _isLoading
                ? ListView.builder(
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
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        PremiumPageHeader.horizontalPadding,
                                  ),
                                  itemCount: _recentSearches.length,
                                  itemBuilder: (context, index) {
                                    final search = _recentSearches[index];
                                    return Padding(
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
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                    : _searchResults.isEmpty
                        ? EmptyState(
                            title: 'No Results',
                            message: 'Try a different search term',
                            iconPath: AppIcons.searchZoomOut,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.spacingSM,
                            ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return ChatListItem(
                                userId: (result['id'] as num).toInt(),
                                name: result['name'] as String? ?? 'User',
                                avatarUrl: result['avatar_url'] as String?,
                                lastMessage: result['last_message'] as String?,
                                lastMessageTime:
                                    result['last_message_time'] as DateTime?,
                                unreadCount:
                                    (result['unread_count'] as num?)?.toInt() ??
                                        0,
                                isOnline: result['is_online'] == true,
                                onTap: () => _handleChatTap(
                                  (result['id'] as num).toInt(),
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
