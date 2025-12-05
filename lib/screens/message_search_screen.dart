// Screen: MessageSearchScreen
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/chat/chat_list_item.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../core/constants/api_endpoints.dart';
import '../pages/chat_page.dart';

/// Message search screen - Search messages
class MessageSearchScreen extends ConsumerStatefulWidget {
  const MessageSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MessageSearchScreen> createState() => _MessageSearchScreenState();
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
      // Fallback to empty recent searches if SharedPreferences fails
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
        ApiEndpoints.messageSearch,
        queryParameters: {
          'query': query,
          'limit': 20,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        final messages = data?['messages'] as List<dynamic>? ?? [];

        // Group messages by chat/conversation
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
              'unread_count': 0, // Could be calculated from API
              'is_online': false, // Could be added to API response
              'is_verified': false, // Could be added to API response
              'is_premium': false, // Could be added to API response
              'chat_id': chatId,
            };
            groupedResults.add(chatMap[chatId]!);
          }
        }

        setState(() {
          _searchResults = groupedResults;
          _isLoading = false;
        });

        // Save to recent searches
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

      // Remove if already exists
      searches.remove(query);

      // Add to beginning
      searches.insert(0, query);

      // Keep only max recent searches
      if (searches.length > _maxRecentSearches) {
        searches.removeRange(_maxRecentSearches, searches.length);
      }

      await _prefs!.setStringList(_recentSearchesKey, searches);
      _loadRecentSearches();
    } catch (e) {
      debugPrint('Failed to save recent search: $e');
      // Continue without saving to avoid crashes
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
      // Continue without removing to avoid crashes
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
      // Continue with empty list
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Search Messages',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                  prefixIcon: Icon(
                    Icons.search,
                    color: secondaryTextColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: secondaryTextColor,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingMD,
                  ),
                ),
                style: AppTypography.body.copyWith(color: textColor),
              ),
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 5,
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 80,
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        ),
                      );
                    },
                  )
                : _searchController.text.isEmpty
                    ? _recentSearches.isEmpty
                        ? EmptyState(
                            title: 'Search Messages',
                            message: 'Enter a name or keyword to search your conversations',
                            icon: Icons.search,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(AppSpacing.spacingLG),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Recent Searches',
                                      style: AppTypography.h3.copyWith(color: textColor),
                                    ),
                                    TextButton(
                                      onPressed: _clearRecentSearches,
                                      child: Text(
                                        'Clear All',
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.accentPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingLG,
                                  ),
                                  itemCount: _recentSearches.length,
                                  itemBuilder: (context, index) {
                                    final search = _recentSearches[index];
                                    return ListTile(
                                      leading: Icon(
                                        Icons.search,
                                        color: secondaryTextColor,
                                      ),
                                      title: Text(
                                        search['query'],
                                        style: AppTypography.body.copyWith(color: textColor),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: secondaryTextColor,
                                          size: 20,
                                        ),
                                        onPressed: () => _removeRecentSearch(search['query']),
                                      ),
                                      onTap: () {
                                        _searchController.text = search['query'];
                                        _performSearch(search['query']);
                                      },
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
                            icon: Icons.search_off,
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
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
