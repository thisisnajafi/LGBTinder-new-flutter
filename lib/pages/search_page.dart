// Screen: SearchPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/ui/filter_chip.dart';
import '../widgets/cards/card_preview_widget.dart';
import '../core/widgets/loading_indicator.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../pages/profile_page.dart';
import '../features/discover/providers/discovery_providers.dart';
import '../features/discover/data/models/discovery_profile.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';

/// Search page - Search and filter profiles
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  List<DiscoveryProfile> _results = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final discoveryService = ref.read(discoveryServiceProvider);
      
      // Build filters based on search query and selected filter
      final Map<String, dynamic> filters = {};
      
      if (_searchQuery.isNotEmpty) {
        filters['query'] = _searchQuery;
      }
      
      // Apply filter type
      if (_selectedFilter == 'verified') {
        filters['verified_only'] = true;
      } else if (_selectedFilter == 'premium') {
        filters['premium_only'] = true;
      } else if (_selectedFilter == 'online') {
        filters['online_only'] = true;
      }
      
      final profiles = await discoveryService.getAdvancedMatches(
        filters: filters.isNotEmpty ? filters : null,
        limit: 50, // Load more results for search
      );

      if (mounted) {
        setState(() {
          _results = profiles;
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

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadResults();
  }

  void _handleFilterTap(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadResults();
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
        title: 'Search',
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
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              style: AppTypography.body.copyWith(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search profiles...',
                hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                prefixIcon: Icon(
                  Icons.search,
                  color: secondaryTextColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: secondaryTextColor,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceElevatedLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingMD,
                ),
              ),
            ),
          ),
          // Filter chips
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingLG,
              vertical: AppSpacing.spacingMD,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => _handleFilterTap('all'),
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  FilterChip(
                    label: 'Verified',
                    isSelected: _selectedFilter == 'verified',
                    onTap: () => _handleFilterTap('verified'),
                    icon: Icons.verified,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  FilterChip(
                    label: 'Premium',
                    isSelected: _selectedFilter == 'premium',
                    onTap: () => _handleFilterTap('premium'),
                    icon: Icons.star,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  FilterChip(
                    label: 'Online',
                    isSelected: _selectedFilter == 'online',
                    onTap: () => _handleFilterTap('online'),
                    icon: Icons.circle,
                  ),
                ],
              ),
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? LoadingIndicator(message: 'Searching...')
                : _hasError
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage ?? 'Failed to load results',
                        onRetry: _loadResults,
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: secondaryTextColor,
                                ),
                                SizedBox(height: AppSpacing.spacingMD),
                                Text(
                                  'No results found',
                                  style: AppTypography.h3.copyWith(
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.spacingSM),
                                Text(
                                  'Try adjusting your search or filters',
                                  style: AppTypography.body.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadResults,
                            child: GridView.builder(
                              padding: EdgeInsets.all(AppSpacing.spacingLG),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final profile = _results[index];
                              return CardPreviewWidget(
                                userId: profile.id,
                                name: profile.firstName,
                                age: profile.age,
                                avatarUrl: profile.primaryImageUrl,
                                isVerified: false, // DiscoveryProfile doesn't have isVerified yet
                                isPremium: false, // DiscoveryProfile doesn't have isPremium yet
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfilePage(
                                        userId: profile.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
