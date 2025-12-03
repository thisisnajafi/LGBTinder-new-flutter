// Widget: RetryButton
// Retry action button
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../buttons/gradient_button.dart';

/// Retry button widget
/// Button for retrying failed operations
class RetryButton extends ConsumerWidget {
  final VoidCallback? onRetry;
  final String? label;
  final bool isLoading;

  const RetryButton({
    Key? key,
    this.onRetry,
    this.label,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientButton(
      text: label ?? 'Retry',
      onPressed: isLoading ? null : onRetry,
      isLoading: isLoading,
      icon: Icons.refresh,
      isFullWidth: false,
    );
  }
}
