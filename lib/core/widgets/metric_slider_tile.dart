import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/border_radius_constants.dart';
import '../theme/spacing_constants.dart';

/// App-wide slider styling (purple track, white thumb).
class AppSliderTheme extends StatelessWidget {
  final Widget child;

  const AppSliderTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = AppColors.accentPurple.withValues(alpha: isDark ? 0.2 : 0.14);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.accentPurple,
        inactiveTrackColor: inactive,
        thumbColor: Colors.white,
        overlayColor: AppColors.accentPurple.withValues(alpha: 0.16),
        trackHeight: 5,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 2,
        ),
        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 2,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: child,
    );
  }
}

/// Slider row for numeric profile metrics (height, weight, etc.).
class MetricSliderTile extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  const MetricSliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  int get _divisions => (max - min).clamp(1, 500);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const Spacer(),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$clamped',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        AppSliderTheme(
          child: Slider(
            value: clamped.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: _divisions,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingXS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min $unit',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              Text(
                '$max $unit',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Height slider — 100–250 cm (matches backend validation).
class HeightSliderTile extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const HeightSliderTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MetricSliderTile(
      label: 'Height',
      value: value,
      min: 100,
      max: 250,
      unit: 'cm',
      onChanged: onChanged,
    );
  }
}

/// Dual-thumb age range picker for profile / discovery preferences.
class AgeRangeSliderTile extends StatelessWidget {
  final int minAge;
  final int maxAge;
  final ValueChanged<RangeValues> onChanged;
  final int absoluteMin;
  final int absoluteMax;

  const AgeRangeSliderTile({
    super.key,
    required this.minAge,
    required this.maxAge,
    required this.onChanged,
    this.absoluteMin = 18,
    this.absoluteMax = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedMin = minAge.clamp(absoluteMin, absoluteMax - 1);
    final clampedMax = maxAge.clamp(clampedMin + 1, absoluteMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Age range',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingXS,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.14),
                    AppColors.accentPink.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                border: Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                '$clampedMin – $clampedMax',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacingMD),
        AppSliderTheme(
          child: RangeSlider(
            values: RangeValues(clampedMin.toDouble(), clampedMax.toDouble()),
            min: absoluteMin.toDouble(),
            max: absoluteMax.toDouble(),
            divisions: absoluteMax - absoluteMin,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingXS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$absoluteMin yrs',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              Text(
                '$absoluteMax yrs',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Weight slider — 30–200 kg (matches backend validation).
class WeightSliderTile extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const WeightSliderTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MetricSliderTile(
      label: 'Weight',
      value: value,
      min: 30,
      max: 200,
      unit: 'kg',
      onChanged: onChanged,
    );
  }
}
