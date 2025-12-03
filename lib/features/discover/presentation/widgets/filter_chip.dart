import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

/// Filter chip widget for discovery filters
/// Displays active filters as chips that can be removed
class FilterChip extends ConsumerWidget {
  final String label;
  final String? value;
  final VoidCallback onRemove;
  final Color? backgroundColor;
  final Color? textColor;

  const FilterChip({
    Key? key,
    required this.label,
    this.value,
    required this.onRemove,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayText = value != null ? '$label: $value' : label;

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: Chip(
        label: Text(
          displayText,
          style: theme.textTheme.labelMedium?.copyWith(
            color: textColor ?? (isDark ? Colors.white : Colors.black87),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor ?? AppColors.primaryLight.withOpacity(0.1),
        side: BorderSide(
          color: backgroundColor ?? AppColors.primaryLight.withOpacity(0.3),
          width: 1,
        ),
        deleteIcon: Icon(
          Icons.close,
          size: 16,
          color: textColor ?? (isDark ? Colors.white70 : Colors.black54),
        ),
        onDeleted: onRemove,
        deleteIconColor: textColor ?? (isDark ? Colors.white70 : Colors.black54),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Active filters display widget
/// Shows all active filters as a row of chips
class ActiveFiltersDisplay extends ConsumerWidget {
  final Map<String, String> activeFilters;
  final Function(String) onRemoveFilter;

  const ActiveFiltersDisplay({
    Key? key,
    required this.activeFilters,
    required this.onRemoveFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        children: activeFilters.entries.map((entry) {
          return FilterChip(
            label: _formatFilterLabel(entry.key),
            value: entry.value,
            onRemove: () => onRemoveFilter(entry.key),
          );
        }).toList(),
      ),
    );
  }

  String _formatFilterLabel(String key) {
    // Convert snake_case to Title Case
    return key.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
