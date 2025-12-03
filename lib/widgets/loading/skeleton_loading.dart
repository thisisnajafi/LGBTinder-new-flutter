/// Skeleton loading widget
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';

/// Skeleton loading widget for showing loading states
class SkeletonLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoading({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: width ?? double.infinity,
      height: height ?? 20,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

/// Skeleton list loading widget
class SkeletonListLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonListLoading({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
          child: Row(
            children: [
              SkeletonLoading(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(30),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoading(height: 16),
                    SizedBox(height: AppSpacing.spacingXS),
                    SkeletonLoading(height: 12, width: 150),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

