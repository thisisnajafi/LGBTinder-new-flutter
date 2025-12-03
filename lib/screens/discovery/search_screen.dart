// Screen: SearchScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/cards/card_preview_widget.dart';
import '../../widgets/loading/skeleton_loader.dart';
import '../../widgets/error_handling/empty_state.dart';
import '../../screens/discovery/filter_screen.dart';

/// Search screen - Advanced search interface
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  int _activeFilterCount = 0;

  // Search filters
  RangeValues _ageRange = const RangeValues(18, 100);
  double? _maxDistance;
  List<String> _selectedGenders = [];
  String? _selectedCountry;
  String? _selectedCity;
  List<String> _selectedInterests = [];
  bool _showVerifiedOnly = false;
  bool _showOnlineOnly = false;
  bool _showPremiumOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilterCount() {
    int count = 0;
    if (_ageRange.start != 18 || _ageRange.end != 100) count++;
    if (_maxDistance != null) count++;
    if (_selectedGenders.isNotEmpty) count++;
    if (_selectedCountry != null) count++;
    if (_selectedCity != null) count++;
    if (_selectedInterests.isNotEmpty) count++;
    if (_showVerifiedOnly) count++;
    if (_showOnlineOnly) count++;
    if (_showPremiumOnly) count++;
    setState(() {
      _activeFilterCount = count;
    });
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty && _activeFilterCount == 0) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      // TODO: Perform search via API
      // GET /api/users/search?query={query}&filters={filters}
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _searchResults = [
            {
              'id': 1,
              'name': 'Alex',
              'age': 28,
              'avatar_url': null,
              'is_verified': true,
              'is_premium': false,
            },
            {
              'id': 2,
              'name': 'Sam',
              'age': 32,
              'avatar_url': null,
              'is_verified': false,
              'is_premium': true,
            },
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FilterScreen(),
      ),
    );

    if (result != null) {
      // Update filters from result
      setState(() {
        if (result['ageRange'] != null) {
          _ageRange = result['ageRange'];
        }
        if (result['maxDistance'] != null) {
          _maxDistance = result['maxDistance'];
        }
        if (result['genders'] != null) {
          _selectedGenders = List<String>.from(result['genders']);
        }
        if (result['verifiedOnly'] != null) {
          _showVerifiedOnly = result['verifiedOnly'];
        }
        if (result['onlineOnly'] != null) {
          _showOnlineOnly = result['onlineOnly'];
        }
        if (result['premiumOnly'] != null) {
          _showPremiumOnly = result['premiumOnly'];
        }
      });
      _updateFilterCount();
      _performSearch();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
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
            child: Row(
              children: [
                Expanded(
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
                      onSubmitted: (_) => _performSearch(),
                      decoration: InputDecoration(
                        hintText: 'Search by name, location, interests...',
                        hintStyle: AppTypography.body.copyWith(
                          color: secondaryTextColor,
                        ),
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
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingMD,
                          vertical: AppSpacing.spacingMD,
                        ),
                      ),
                      style: AppTypography.body.copyWith(color: textColor),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: textColor,
                      ),
                      onPressed: _openFilters,
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? GridView.builder(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return SkeletonLoader(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      );
                    },
                  )
                : _isSearching && _searchResults.isEmpty
                    ? EmptyState(
                        title: 'No results found',
                        message: 'Try adjusting your search or filters',
                        icon: Icons.search_off,
                      )
                    : !_isSearching
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 64,
                                  color: secondaryTextColor,
                                ),
                                SizedBox(height: AppSpacing.spacingLG),
                                Text(
                                  'Start searching',
                                  style: AppTypography.h2.copyWith(
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.spacingSM),
                                Text(
                                  'Search by name, location, or interests',
                                  style: AppTypography.body.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.all(AppSpacing.spacingLG),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return CardPreviewWidget(
                                userId: user['id'] ?? 0,
                                name: user['name'] ?? 'User',
                                age: user['age'],
                                avatarUrl: user['avatar_url'],
                                isVerified: user['is_verified'] ?? false,
                                isPremium: user['is_premium'] ?? false,
                                onTap: () {
                                  // TODO: Navigate to profile detail
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('View profile: ${user['name']}'),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: _isSearching && _searchResults.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _performSearch,
              backgroundColor: AppColors.accentPurple,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Refresh',
                style: AppTypography.button.copyWith(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
