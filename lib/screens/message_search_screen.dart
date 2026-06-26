// Screen: MessageSearchScreen
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
import '../widgets/chat/chat_list_item.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../core/constants/api_endpoints.dart';
import '../pages/chat_page.dart';

/// Message search screen - Search messages
class MessageSearchScreen extends ConsumerStatefulWidget {
  const MessageSearchScreen({super.key});

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
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadRecentSearches();
    } catch (e) {
      debugPrint('Failed to initialize SharedPreferences: $e');
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

  void _onSearchChanged() {
    setState(() {});
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    _performSearch(query);
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
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        final messages = data?['messages'] as List<dynamic>? ?? [];

        final groupedResults = <Map<String, dynamic>>[];
        final chatMap = <int, Map<String, dynamic>>{};

        for (final message in messages) {
          final messageData = message as Map<String, dynamic>;
          final otherUser = messageData['other_user'] as Map<String, dynamic>;
          final chatId = messageData['chat_id'] as int;

          if (!chatMap.containsKey(chatId)) {
            chatMap[chatId] = {
              'id': otherUser['id'],
              'name': otherUser['name'],
              'avatar_url': otherUser['avatar_url'],
              'last_message': messageData['message'],
              'last_message_time': DateTime.parse(messageData['created_at']),
              'unread_count': 0,
              'is_online': false,
              'is_verified': false,
              'is_premium': false,
              'chat_id': chatId,
            };
            groupedResults.add(chatMap[chatId]!);
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
      debugPrint('Failed to load recent searches: $e');
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
      debugPrint('Failed to save recent search: $e');
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
      debugPrint('Failed to remove recent search: $e');
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
      debugPrint('Failed to clear recent searches: $e');
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
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: AppTypography.body.copyWith(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle:
                            AppTypography.body.copyWith(color: secondaryTextColor),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacingSM,
                        ),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    PremiumTapScale(
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
                                userId: result['id'],
                                name: result['name'],
                                avatarUrl: result['avatar_url'],
                                lastMessage: result['last_message'],
                                lastMessageTime: result['last_message_time'],
                                unreadCount: result['unread_count'],
                                isOnline: result['is_online'],
                                onTap: () => _handleChatTap(result['id']),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
