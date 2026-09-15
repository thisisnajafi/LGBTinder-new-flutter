import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../shared/widgets/lazy_load_list.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../data/models/google_play_purchase_history.dart';
import '../../providers/payment_providers.dart';
import '../widgets/purchase_filter_chip.dart';
import '../widgets/purchase_history_item.dart';
import 'purchase_details_screen.dart';

/// Google Play purchase history with filter chips and paginated lazy list
/// (PERF-FEAT-PAY-003).
class GooglePlayPurchaseHistoryScreen extends ConsumerStatefulWidget {
  const GooglePlayPurchaseHistoryScreen({super.key});

  @override
  ConsumerState<GooglePlayPurchaseHistoryScreen> createState() =>
      _GooglePlayPurchaseHistoryScreenState();
}

class _GooglePlayPurchaseHistoryScreenState
    extends ConsumerState<GooglePlayPurchaseHistoryScreen> {
  List<GooglePlayPurchaseHistory> _purchases = const [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  String? _selectedType;
  String? _selectedStatus;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPurchases(refresh: true);
    });
  }

  Future<void> _loadPurchases({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      if (refresh) _purchases = const [];
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final purchases = await paymentService.getGooglePlayPurchaseHistory(
        type: _selectedType,
        status: _selectedStatus,
        page: _currentPage,
        limit: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _purchases = refresh ? purchases : [..._purchases, ...purchases];
        _hasMore = purchases.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _loadMore() async {
    if (_isLoading || !_hasMore) return false;
    _currentPage++;
    await _loadPurchases();
    return _hasMore;
  }

  void _onFilterChanged(String? type, String? status) {
    setState(() {
      _selectedType = type;
      _selectedStatus = status;
    });
    _loadPurchases(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return AppPageScaffold(
      title: 'Purchase History',
      showBackButton: true,
      backgroundColor: backgroundColor,
      action: IconButton(
        tooltip: 'Refresh',
        onPressed: _isLoading ? null : () => _loadPurchases(refresh: true),
        icon: AppSvgIcon(
          assetPath: AppIcons.refreshCircle,
          size: 22,
          color: theme.colorScheme.onSurface,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingSM,
            ),
            color: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by',
                  style: AppTypography.body.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Wrap(
                  spacing: AppSpacing.spacingSM,
                  runSpacing: AppSpacing.spacingSM,
                  children: [
                    PurchaseFilterChip(
                      label: 'All Types',
                      isSelected: _selectedType == null,
                      onSelected: () =>
                          _onFilterChanged(null, _selectedStatus),
                    ),
                    PurchaseFilterChip(
                      label: 'Subscriptions',
                      isSelected: _selectedType == 'subscription',
                      onSelected: () =>
                          _onFilterChanged('subscription', _selectedStatus),
                    ),
                    PurchaseFilterChip(
                      label: 'One-time',
                      isSelected: _selectedType == 'one_time',
                      onSelected: () =>
                          _onFilterChanged('one_time', _selectedStatus),
                    ),
                    PurchaseFilterChip(
                      label: 'All Status',
                      isSelected: _selectedStatus == null,
                      onSelected: () => _onFilterChanged(_selectedType, null),
                    ),
                    PurchaseFilterChip(
                      label: 'Active',
                      isSelected: _selectedStatus == 'completed',
                      onSelected: () =>
                          _onFilterChanged(_selectedType, 'completed'),
                    ),
                    PurchaseFilterChip(
                      label: 'Cancelled',
                      isSelected: _selectedStatus == 'cancelled',
                      onSelected: () =>
                          _onFilterChanged(_selectedType, 'cancelled'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _purchases.isEmpty
                ? const SkeletonLoading()
                : _hasError && _purchases.isEmpty
                    ? ErrorDisplayWidget(
                        errorMessage:
                            _errorMessage ?? 'Failed to load purchases',
                        onRetry: () => _loadPurchases(refresh: true),
                      )
                    : LazyLoadList<GooglePlayPurchaseHistory>(
                        items: _purchases,
                        isLoading: _isLoading,
                        hasMore: _hasMore,
                        hasError: _hasError && _purchases.isEmpty,
                        onLoadMore: _loadMore,
                        onRefresh: () => _loadPurchases(refresh: true),
                        padding: const EdgeInsets.all(AppSpacing.spacingMD),
                        physics: AppScroll.bouncing,
                        emptyWidget: _buildEmptyState(
                          textColor,
                          secondaryTextColor,
                        ),
                        errorWidget: ErrorDisplayWidget(
                          errorMessage:
                              _errorMessage ?? 'Failed to load purchases',
                          onRetry: () => _loadPurchases(refresh: true),
                        ),
                        itemBuilder: (context, purchase, _) {
                          return PurchaseHistoryItem(
                            purchase: purchase,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PurchaseDetailsScreen(
                                    purchaseId: purchase.id,
                                    initialPurchase: purchase,
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

  Widget _buildEmptyState(Color textColor, Color secondaryTextColor) {
    return ResponsiveGrid.constrained(
      context,
      Center(
        child: Padding(
          padding: ResponsivePadding.page(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                assetPath: AppIcons.receipt,
                size: 64,
                color: secondaryTextColor,
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              AppText(
                'No Purchases Found',
                style: AppTypography.h2.copyWith(color: textColor),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.spacingSM),
              AppText(
                "You haven't made any Google Play purchases yet.",
                style: AppTypography.body.copyWith(color: secondaryTextColor),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              GradientButton(
                text: 'Browse Plans',
                iconPath: AppIcons.discover,
                isFullWidth: false,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
