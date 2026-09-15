import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../data/models/google_play_purchase_history.dart';
import '../../providers/payment_providers.dart';

/// Purchase details — paints [initialPurchase] immediately (PERF-FEAT-PAY-007).
class PurchaseDetailsScreen extends ConsumerStatefulWidget {
  final int purchaseId;
  final GooglePlayPurchaseHistory? initialPurchase;

  const PurchaseDetailsScreen({
    super.key,
    required this.purchaseId,
    this.initialPurchase,
  });

  @override
  ConsumerState<PurchaseDetailsScreen> createState() =>
      _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends ConsumerState<PurchaseDetailsScreen> {
  GooglePlayPurchaseHistory? _purchase;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _purchase = widget.initialPurchase;
    if (_purchase != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPurchaseDetails();
    });
  }

  Future<void> _loadPurchaseDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final purchase = await paymentService.getGooglePlayPurchaseDetails(
        widget.purchaseId,
      );

      if (!mounted) return;
      setState(() {
        _purchase = purchase;
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
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final purchase = _purchase;

    return AppPageScaffold(
      title: 'Purchase Details',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: _isLoading && purchase == null
          ? const SkeletonLoading()
          : _hasError && purchase == null
              ? ErrorDisplayWidget(
                  errorMessage:
                      _errorMessage ?? 'Failed to load purchase details',
                  onRetry: _loadPurchaseDetails,
                )
              : purchase == null
                  ? Center(
                      child: Text(
                        'Purchase not found',
                        style: AppTypography.body.copyWith(color: textColor),
                      ),
                    )
                  : _PurchaseDetailsBody(
                      purchase: purchase,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
    );
  }
}

class _PurchaseDetailsBody extends StatelessWidget {
  const _PurchaseDetailsBody({
    required this.purchase,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final GooglePlayPurchaseHistory purchase;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid.constrained(
      context,
      SingleChildScrollView(
        padding: ResponsivePadding.page(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              title: 'Purchase Information',
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              children: [
                _DetailRow(
                  label: 'Product',
                  value: purchase.productName,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _DetailRow(
                  label: 'Product ID',
                  value: purchase.productId,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  isMonospace: true,
                ),
                _DetailRow(
                  label: 'Type',
                  value: purchase.isSubscription
                      ? 'Subscription'
                      : 'One-time Purchase',
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _DetailRow(
                  label: 'Status',
                  value: purchase.status.toUpperCase(),
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _DetailRow(
                  label: 'Price',
                  value: purchase.formattedPrice,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                if (purchase.purchaseDate != null)
                  _DetailRow(
                    label: 'Purchase Date',
                    value: DateFormat('MMM d, y HH:mm')
                        .format(purchase.purchaseDate!),
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                if (purchase.expiryDate != null)
                  _DetailRow(
                    label: 'Expiry Date',
                    value:
                        DateFormat('MMM d, y HH:mm').format(purchase.expiryDate!),
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                if (purchase.orderId != null)
                  _DetailRow(
                    label: 'Order ID',
                    value: purchase.orderId!,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isMonospace: true,
                  ),
                _DetailRow(
                  label: 'Auto Renewing',
                  value: purchase.autoRenewing ? 'Yes' : 'No',
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ],
            ),
            if (purchase.isSubscription && purchase.subscription != null) ...[
              const SizedBox(height: AppSpacing.spacingLG),
              _InfoCard(
                title: 'Subscription Details',
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                children: [
                  if (purchase.subscription!['plan'] != null)
                    _DetailRow(
                      label: 'Plan',
                      value: purchase.subscription!['plan']['title']
                              ?.toString() ??
                          'N/A',
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  if (purchase.subscription!['billing_cycle'] != null)
                    _DetailRow(
                      label: 'Billing Cycle',
                      value: purchase.subscription!['billing_cycle']
                          .toString()
                          .toUpperCase(),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  if (purchase.subscription!['start_date'] != null)
                    _DetailRow(
                      label: 'Start Date',
                      value: DateFormat('MMM d, y').format(
                        DateTime.parse(
                          purchase.subscription!['start_date'].toString(),
                        ),
                      ),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  if (purchase.subscription!['end_date'] != null)
                    _DetailRow(
                      label: 'End Date',
                      value: DateFormat('MMM d, y').format(
                        DateTime.parse(
                          purchase.subscription!['end_date'].toString(),
                        ),
                      ),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                ],
              ),
            ],
            if (!purchase.isSubscription && purchase.superlikePack != null) ...[
              const SizedBox(height: AppSpacing.spacingLG),
              _InfoCard(
                title: 'Superlike Pack Details',
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                children: [
                  if (purchase.superlikePack!['quantity'] != null)
                    _DetailRow(
                      label: 'Quantity',
                      value: purchase.superlikePack!['quantity'].toString(),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  if (purchase.superlikePack!['remaining'] != null)
                    _DetailRow(
                      label: 'Remaining',
                      value: purchase.superlikePack!['remaining'].toString(),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                ],
              ),
            ],
            if (purchase.marketingAttribution != null) ...[
              const SizedBox(height: AppSpacing.spacingLG),
              _InfoCard(
                title: 'Marketing Attribution',
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                children: [
                  if (purchase.marketingAttribution!['utm_source'] != null)
                    _DetailRow(
                      label: 'Source',
                      value: purchase.marketingAttribution!['utm_source']
                          .toString(),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  if (purchase.marketingAttribution!['utm_campaign'] != null)
                    _DetailRow(
                      label: 'Campaign',
                      value: purchase.marketingAttribution!['utm_campaign']
                          .toString(),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  if (purchase.marketingAttribution!['campaign_id'] != null)
                    _DetailRow(
                      label: 'Campaign ID',
                      value: purchase.marketingAttribution!['campaign_id']
                          .toString(),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.children,
    required this.surfaceColor,
    required this.borderColor,
  });

  final String title;
  final List<Widget> children;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.secondaryTextColor,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              style: AppTypography.body.copyWith(
                color: secondaryTextColor,
              ),
              maxLines: 2,
            ),
          ),
          Expanded(
            flex: 3,
            child: AppText(
              value,
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
