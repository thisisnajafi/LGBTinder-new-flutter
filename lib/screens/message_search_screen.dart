// Screen: MessageSearchScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/chat/chat_list_item.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchChanged);
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
      // TODO: Search messages via API
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _searchResults = [
          {
            'id': 1,
            'name': 'Alex',
            'avatar_url': 'https://via.placeholder.com/200',
            'last_message': 'Hey! How are you?',
            'last_message_time': DateTime.now().subtract(const Duration(hours: 2)),
            'unread_count': 0,
            'is_online': false,
            'is_verified': true,
            'is_premium': false,
          },
          {
            'id': 2,
            'name': 'Jordan',
            'avatar_url': 'https://via.placeholder.com/200',
            'last_message': 'Thanks for the message!',
            'last_message_time': DateTime.now().subtract(const Duration(days: 1)),
            'unread_count': 2,
            'is_online': true,
            'is_verified': false,
            'is_premium': true,
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    // TODO: Load recent searches from storage
    setState(() {
      _recentSearches = [
        {
          'id': 1,
          'name': 'Alex',
          'avatar_url': 'https://via.placeholder.com/200',
        },
      ];
    });
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
                                child: Text(
                                  'Recent Searches',
                                  style: AppTypography.h3.copyWith(color: textColor),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingLG,
                                  ),
                                  itemCount: _recentSearches.length,
                                  itemBuilder: (context, index) {
                                    final user = _recentSearches[index];
                                    return ChatListItem(
                                      userId: user['id'],
                                      name: user['name'],
                                      avatarUrl: user['avatar_url'],
                                      lastMessage: null,
                                      lastMessageTime: null,
                                      unreadCount: 0,
                                      isOnline: false,
                                      onTap: () => _handleChatTap(user['id']),
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
