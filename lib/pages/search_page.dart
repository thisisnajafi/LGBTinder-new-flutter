// Screen: SearchPage — premium search and filter profiles
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/discover/data/models/discovery_profile.dart';
import '../features/discover/providers/discovery_providers.dart';
import '../routes/app_router.dart';
import '../shared/models/api_error.dart';
import '../widgets/cards/card_preview_widget.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../core/widgets/loading_indicator.dart';

/// Search page — search and filter profiles with premium shell UI.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

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

  static const _filters = <({String id, String label, String? iconPath})>[
    (id: 'all', label: 'All', iconPath: null),
    (id: 'verified', label: 'Verified', iconPath: null),
    (id: 'premium', label: 'Premium', iconPath: null),
    (id: 'online', label: 'Online', iconPath: null),
  ];

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
      final Map<String, dynamic> filters = {};

      if (_searchQuery.isNotEmpty) {
        filters['query'] = _searchQuery;
      }

      if (_selectedFilter == 'verified') {
        filters['verified_only'] = true;
      } else if (_selectedFilter == 'premium') {
        filters['premium_only'] = true;
      } else if (_selectedFilter == 'online') {
        filters['online_only'] = true;
      }

      final profiles = await discoveryService.getAdvancedMatches(
        filters: filters.isNotEmpty ? filters : null,
        limit: 50,
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
    setState(() => _searchQuery = query);
    _loadResults();
  }

  void _handleFilterTap(String filter) {
    setState(() => _selectedFilter = filter);
    _loadResults();
  }

  void _openProfile(DiscoveryProfile profile) {
    final target = Uri(
      path: AppRoutes.profileDetail,
      queryParameters: {'userId': profile.id.toString()},
    ).toString();
    context.push(target);
  }

  String? _filterIconPath(String id) {
    return switch (id) {
      'verified' => AppIcons.verify,
      'premium' => AppIcons.star,
      'online' => null,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AppSettingsDetailScaffold(
      title: 'Search',
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
                      onChanged: _handleSearch,
                      style: AppTypography.body.copyWith(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search profiles...',
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
                  if (_searchQuery.isNotEmpty)
                    PremiumTapScale(
                      onTap: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PremiumPageHeader.horizontalPadding,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _filters.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.spacingSM),
                    _SearchFilterChip(
                      label: _filters[i].label,
                      iconPath: _filterIconPath(_filters[i].id),
                      showOnlineDot: _filters[i].id == 'online',
                      isSelected: _selectedFilter == _filters[i].id,
                      onTap: () => _handleFilterTap(_filters[i].id),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Searching...')
                : _hasError
                    ? ErrorDisplayWidget(
                        errorMessage:
                            _errorMessage ?? 'Failed to load results',
                        onRetry: _loadResults,
                      )
                    : _results.isEmpty
                        ? _SearchEmptyState(
                            secondaryTextColor: secondaryTextColor,
                            textColor: textColor,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadResults,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(
                                PremiumPageHeader.horizontalPadding,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: AppSpacing.spacingMD,
                                mainAxisSpacing: AppSpacing.spacingMD,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final profile = _results[index];
                                return PremiumTapScale(
                                  onTap: () => _openProfile(profile),
                                  semanticLabel: 'Open ${profile.firstName}',
                                  child: CardPreviewWidget(
                                    userId: profile.id,
                                    name: profile.firstName,
                                    age: profile.age,
                                    avatarUrl: profile.primaryImageUrl,
                                    isVerified: false,
                                    isPremium: false,
                                    onTap: () => _openProfile(profile),
                                  ),
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

class _SearchFilterChip extends StatelessWidget {
  const _SearchFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconPath,
    this.showOnlineDot = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? iconPath;
  final bool showOnlineDot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumTapScale(
      onTap: onTap,
      semanticLabel: 'Filter $label',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isSelected
              ? null
              : AppColors.accentViolet.withValues(alpha: 0.08),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.accentViolet.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showOnlineDot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.onlineGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.spacingXS),
            ] else if (iconPath != null) ...[
              AppSvgIcon(
                assetPath: iconPath!,
                size: 14,
                color: isSelected ? Colors.white : AppColors.accentViolet,
              ),
              const SizedBox(width: AppSpacing.spacingXS),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.accentViolet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.textColor,
    required this.secondaryTextColor,
  });

  final Color textColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PremiumPageHeader.horizontalPadding,
        ),
        child: PremiumShell(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentViolet.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.search,
                    size: 32,
                    color: AppColors.accentViolet,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              Text(
                'No results found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.spacingSM),
              Text(
                'Try adjusting your search or filters',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
