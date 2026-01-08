import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../data/models/google_play_purchase_history.dart';
import '../../data/services/payment_service.dart';
import '../../providers/payment_providers.dart';
import '../widgets/purchase_history_item.dart';
import '../widgets/purchase_filter_chip.dart';
import 'purchase_details_screen.dart';

/// Google Play Purchase History Screen
/// Displays user's Google Play purchases with filtering options
class GooglePlayPurchaseHistoryScreen extends ConsumerStatefulWidget {
  const GooglePlayPurchaseHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GooglePlayPurchaseHistoryScreen> createState() => _GooglePlayPurchaseHistoryScreenState();
}

class _GooglePlayPurchaseHistoryScreenState extends ConsumerState<GooglePlayPurchaseHistoryScreen> {
  List<GooglePlayPurchaseHistory> _purchases = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  
  String? _selectedType; // 'subscription', 'one_time', or null for all
  String? _selectedStatus; // 'completed', 'pending', 'cancelled', 'refunded', or null for all
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _purchases = [];
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final purchases = await paymentService.getGooglePlayPurchaseHistory(
        type: _selectedType,
        status: _selectedStatus,
        page: _currentPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _purchases = purchases;
          } else {
            _purchases.addAll(purchases);
          }
          _hasMore = purchases.length == _pageSize;
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

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      setState(() {
        _currentPage++;
      });
      _loadPurchases();
    }
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
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Purchase History',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: () => _loadPurchases(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: EdgeInsets.symmetric(
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
                SizedBox(height: AppSpacing.spacingSM),
                Wrap(
                  spacing: AppSpacing.spacingSM,
                  runSpacing: AppSpacing.spacingSM,
                  children: [
                    PurchaseFilterChip(
                      label: 'All Types',
                      isSelected: _selectedType == null,
                      onSelected: () => _onFilterChanged(null, _selectedStatus),
                    ),
                    PurchaseFilterChip(
                      label: 'Subscriptions',
                      isSelected: _selectedType == 'subscription',
                      onSelected: () => _onFilterChanged('subscription', _selectedStatus),
                    ),
                    PurchaseFilterChip(
                      label: 'One-time',
                      isSelected: _selectedType == 'one_time',
                      onSelected: () => _onFilterChanged('one_time', _selectedStatus),
                    ),
                    PurchaseFilterChip(
                      label: 'All Status',
                      isSelected: _selectedStatus == null,
                      onSelected: () => _onFilterChanged(_selectedType, null),
                    ),
                    PurchaseFilterChip(
                      label: 'Active',
                      isSelected: _selectedStatus == 'completed',
                      onSelected: () => _onFilterChanged(_selectedType, 'completed'),
                    ),
                    PurchaseFilterChip(
                      label: 'Cancelled',
                      isSelected: _selectedStatus == 'cancelled',
                      onSelected: () => _onFilterChanged(_selectedType, 'cancelled'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Purchases List
          Expanded(
            child: _isLoading && _purchases.isEmpty
                ? SkeletonLoading()
                : _hasError && _purchases.isEmpty
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage ?? 'Failed to load purchases',
                        onRetry: () => _loadPurchases(refresh: true),
                      )
                    : _purchases.isEmpty
                        ? _buildEmptyState(textColor, secondaryTextColor)
                        : RefreshIndicator(
                            onRefresh: () => _loadPurchases(refresh: true),
                            child: ListView.builder(
                              padding: EdgeInsets.all(AppSpacing.spacingMD),
                              itemCount: _purchases.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _purchases.length) {
                                  // Load more indicator
                                  _loadMore();
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(AppSpacing.spacingMD),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final purchase = _purchases[index];
                                return PurchaseHistoryItem(
                                  purchase: purchase,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PurchaseDetailsScreen(
                                          purchaseId: purchase.id,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color secondaryTextColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingLG),
            Text(
              'No Purchases Found',
              style: AppTypography.h2.copyWith(color: textColor),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              'You haven\'t made any Google Play purchases yet.',
              style: AppTypography.body.copyWith(color: secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingLG),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.explore),
              label: Text('Browse Plans'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingLG,
                  vertical: AppSpacing.spacingMD,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
