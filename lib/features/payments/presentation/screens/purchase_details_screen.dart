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

/// Purchase Details Screen
/// Shows detailed information about a specific Google Play purchase
class PurchaseDetailsScreen extends ConsumerStatefulWidget {
  final int purchaseId;

  const PurchaseDetailsScreen({
    Key? key,
    required this.purchaseId,
  }) : super(key: key);

  @override
  ConsumerState<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends ConsumerState<PurchaseDetailsScreen> {
  GooglePlayPurchaseHistory? _purchase;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPurchaseDetails();
  }

  Future<void> _loadPurchaseDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final purchase = await paymentService.getGooglePlayPurchaseDetails(widget.purchaseId);

      if (mounted) {
        setState(() {
          _purchase = purchase;
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
        title: 'Purchase Details',
        showBackButton: true,
      ),
      body: _isLoading
          ? SkeletonLoading()
          : _hasError
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load purchase details',
                  onRetry: _loadPurchaseDetails,
                )
              : _purchase == null
                  ? Center(
                      child: Text(
                        'Purchase not found',
                        style: AppTypography.body.copyWith(color: textColor),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(AppSpacing.spacingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Purchase Info Card
                          _buildInfoCard(
                            'Purchase Information',
                            [
                              _buildDetailRow('Product', _purchase!.productName, textColor, secondaryTextColor),
                              _buildDetailRow('Product ID', _purchase!.productId, textColor, secondaryTextColor, isMonospace: true),
                              _buildDetailRow('Type', _purchase!.isSubscription ? 'Subscription' : 'One-time Purchase', textColor, secondaryTextColor),
                              _buildDetailRow('Status', _purchase!.status.toUpperCase(), textColor, secondaryTextColor),
                              _buildDetailRow('Price', _purchase!.formattedPrice, textColor, secondaryTextColor),
                              if (_purchase!.purchaseDate != null)
                                _buildDetailRow(
                                  'Purchase Date',
                                  DateFormat('MMM d, y HH:mm').format(_purchase!.purchaseDate!),
                                  textColor,
                                  secondaryTextColor,
                                ),
                              if (_purchase!.expiryDate != null)
                                _buildDetailRow(
                                  'Expiry Date',
                                  DateFormat('MMM d, y HH:mm').format(_purchase!.expiryDate!),
                                  textColor,
                                  secondaryTextColor,
                                ),
                              if (_purchase!.orderId != null)
                                _buildDetailRow('Order ID', _purchase!.orderId!, textColor, secondaryTextColor, isMonospace: true),
                              _buildDetailRow('Auto Renewing', _purchase!.autoRenewing ? 'Yes' : 'No', textColor, secondaryTextColor),
                            ],
                            surfaceColor,
                            borderColor,
                          ),

                          // Subscription Details (if applicable)
                          if (_purchase!.isSubscription && _purchase!.subscription != null) ...[
                            SizedBox(height: AppSpacing.spacingLG),
                            _buildInfoCard(
                              'Subscription Details',
                              [
                                if (_purchase!.subscription!['plan'] != null)
                                  _buildDetailRow(
                                    'Plan',
                                    _purchase!.subscription!['plan']['title']?.toString() ?? 'N/A',
                                    textColor,
                                    secondaryTextColor,
                                  ),
                                if (_purchase!.subscription!['billing_cycle'] != null)
                                  _buildDetailRow(
                                    'Billing Cycle',
                                    _purchase!.subscription!['billing_cycle'].toString().toUpperCase(),
                                    textColor,
                                    secondaryTextColor,
                                  ),
                                if (_purchase!.subscription!['start_date'] != null)
                                  _buildDetailRow(
                                    'Start Date',
                                    DateFormat('MMM d, y').format(DateTime.parse(_purchase!.subscription!['start_date'])),
                                    textColor,
                                    secondaryTextColor,
                                  ),
                                if (_purchase!.subscription!['end_date'] != null)
                                  _buildDetailRow(
                                    'End Date',
                                    DateFormat('MMM d, y').format(DateTime.parse(_purchase!.subscription!['end_date'])),
                                    textColor,
                                    secondaryTextColor,
                                  ),
                              ],
                              surfaceColor,
                              borderColor,
                            ),
                          ],

                          // Superlike Pack Details (if applicable)
                          if (!_purchase!.isSubscription && _purchase!.superlikePack != null) ...[
                            SizedBox(height: AppSpacing.spacingLG),
                            _buildInfoCard(
                              'Superlike Pack Details',
                              [
                                if (_purchase!.superlikePack!['quantity'] != null)
                                  _buildDetailRow(
                                    'Quantity',
                                    _purchase!.superlikePack!['quantity'].toString(),
                                    textColor,
                                    secondaryTextColor,
                                  ),
                                if (_purchase!.superlikePack!['remaining'] != null)
                                  _buildDetailRow(
                                    'Remaining',
                                    _purchase!.superlikePack!['remaining'].toString(),
                                    textColor,
                                    secondaryTextColor,
                                  ),
                              ],
                              surfaceColor,
                              borderColor,
                            ),
                          ],

                          // Marketing Attribution (if available)
                          if (_purchase!.marketingAttribution != null) ...[
                            SizedBox(height: AppSpacing.spacingLG),
                            _buildInfoCard(
                              'Marketing Attribution',
                              [
                                if (_purchase!.marketingAttribution!['utm_source'] != null)
                                  _buildDetailRow(
                                    'Source',
                                    _purchase!.marketingAttribution!['utm_source'].toString(),
                                    textColor,
                                    secondaryTextColor,
                                  ),
                                if (_purchase!.marketingAttribution!['utm_campaign'] != null)
                                  _buildDetailRow(
                                    'Campaign',
                                    _purchase!.marketingAttribution!['utm_campaign'].toString(),
                                    textColor,
                                    secondaryTextColor,
                                  ),
                                if (_purchase!.marketingAttribution!['campaign_id'] != null)
                                  _buildDetailRow(
                                    'Campaign ID',
                                    _purchase!.marketingAttribution!['campaign_id'].toString(),
                                    textColor,
                                    secondaryTextColor,
                                  ),
                              ],
                              surfaceColor,
                              borderColor,
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children, Color surfaceColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor,
    Color secondaryTextColor, {
    bool isMonospace = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
