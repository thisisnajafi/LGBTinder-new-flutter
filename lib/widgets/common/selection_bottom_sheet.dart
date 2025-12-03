import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../features/reference_data/data/models/reference_item.dart';
import '../../core/utils/app_icons.dart';

/// Reusable bottom sheet for single and multi-select dropdowns
class SelectionBottomSheet {
  /// Show single select bottom sheet
  static Future<T?> showSingleSelect<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) getTitle,
    T? selectedItem,
    bool searchable = false,
    String Function(T)? getSearchText,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SingleSelectBottomSheet<T>(
        title: title,
        items: items,
        getTitle: getTitle,
        selectedItem: selectedItem,
        searchable: searchable,
        getSearchText: getSearchText ?? getTitle,
      ),
    );
  }

  /// Show multi-select bottom sheet
  static Future<List<T>?> showMultiSelect<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) getTitle,
    required List<T> selectedItems,
    bool searchable = false,
    String Function(T)? getSearchText,
    int? Function(T, T)? compareItems,
  }) async {
    return await showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MultiSelectBottomSheet<T>(
        title: title,
        items: items,
        getTitle: getTitle,
        selectedItems: selectedItems,
        searchable: searchable,
        getSearchText: getSearchText ?? getTitle,
        compareItems: compareItems,
      ),
    );
  }
}

/// Single select bottom sheet widget
class _SingleSelectBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) getTitle;
  final T? selectedItem;
  final bool searchable;
  final String Function(T) getSearchText;

  const _SingleSelectBottomSheet({
    required this.title,
    required this.items,
    required this.getTitle,
    this.selectedItem,
    this.searchable = false,
    required this.getSearchText,
  });

  @override
  State<_SingleSelectBottomSheet<T>> createState() =>
      _SingleSelectBottomSheetState<T>();
}

class _SingleSelectBottomSheetState<T>
    extends State<_SingleSelectBottomSheet<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    if (!widget.searchable) return;

    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) =>
                widget.getSearchText(item).toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: viewInsets),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.radiusXL),
            topRight: Radius.circular(AppRadius.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: AppSpacing.spacingMD),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: secondaryTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.h2.copyWith(color: textColor),
                ),
                IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.close,
                    size: 24,
                    color: secondaryTextColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Search field (if searchable)
          if (widget.searchable) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
                    child: AppSvgIcon(
                      assetPath: AppIcons.search,
                      size: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                  ),
                ),
                style: AppTypography.body.copyWith(color: textColor),
              ),
            ),
            SizedBox(height: AppSpacing.spacingMD),
          ],
          // Items list
          Flexible(
            child: _filteredItems.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(AppSpacing.spacingXXL),
                    child: Text(
                      'No items found',
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.selectedItem != null &&
                          _areItemsEqual(item, widget.selectedItem!);

                      return InkWell(
                        onTap: () => Navigator.of(context).pop(item),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingLG,
                            vertical: AppSpacing.spacingMD,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentPurple.withOpacity(0.1)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: borderColor.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.getTitle(item),
                                  style: AppTypography.body.copyWith(
                                    color: isSelected
                                        ? AppColors.accentPurple
                                        : textColor,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                AppSvgIcon(
                                  assetPath: AppIcons.checkCircle,
                                  size: 24,
                                  color: AppColors.accentPurple,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
  }

  bool _areItemsEqual(T a, T b) {
    if (a is ReferenceItem && b is ReferenceItem) {
      return a.id == b.id;
    }
    return a == b;
  }
}

/// Multi-select bottom sheet widget
class _MultiSelectBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) getTitle;
  final List<T> selectedItems;
  final bool searchable;
  final String Function(T) getSearchText;
  final int? Function(T, T)? compareItems;

  const _MultiSelectBottomSheet({
    required this.title,
    required this.items,
    required this.getTitle,
    required this.selectedItems,
    this.searchable = false,
    required this.getSearchText,
    this.compareItems,
  });

  @override
  State<_MultiSelectBottomSheet<T>> createState() =>
      _MultiSelectBottomSheetState<T>();
}

class _MultiSelectBottomSheetState<T>
    extends State<_MultiSelectBottomSheet<T>> {
  late List<T> _filteredItems;
  late Set<T> _selectedItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _selectedItems = Set.from(widget.selectedItems);
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    if (!widget.searchable) return;

    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) =>
                widget.getSearchText(item).toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleSelection(T item) {
    setState(() {
      if (_isSelected(item)) {
        _selectedItems.removeWhere((selected) => _areItemsEqual(selected, item));
      } else {
        _selectedItems.add(item);
      }
    });
  }

  bool _isSelected(T item) {
    return _selectedItems.any((selected) => _areItemsEqual(selected, item));
  }

  bool _areItemsEqual(T a, T b) {
    if (a is ReferenceItem && b is ReferenceItem) {
      return a.id == b.id;
    }
    if (widget.compareItems != null) {
      return widget.compareItems!(a, b) == 0;
    }
    return a == b;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: viewInsets),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.radiusXL),
            topRight: Radius.circular(AppRadius.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: AppSpacing.spacingMD),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: secondaryTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.h2.copyWith(color: textColor),
                    ),
                    if (_selectedItems.isNotEmpty)
                      Text(
                        '${_selectedItems.length} selected',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentPurple,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (_selectedItems.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedItems.clear();
                          });
                        },
                        child: Text(
                          'Clear',
                          style: AppTypography.button.copyWith(
                            color: AppColors.accentPurple,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: AppSvgIcon(
                        assetPath: AppIcons.close,
                        size: 24,
                        color: secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Search field (if searchable)
          if (widget.searchable) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
                    child: AppSvgIcon(
                      assetPath: AppIcons.search,
                      size: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                  ),
                ),
                style: AppTypography.body.copyWith(color: textColor),
              ),
            ),
            SizedBox(height: AppSpacing.spacingMD),
          ],
          // Items list
          Flexible(
            child: _filteredItems.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(AppSpacing.spacingXXL),
                    child: Text(
                      'No items found',
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = _isSelected(item);

                      return InkWell(
                        onTap: () => _toggleSelection(item),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingLG,
                            vertical: AppSpacing.spacingMD,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentPurple.withOpacity(0.1)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: borderColor.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accentPurple
                                        : borderColor,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? AppColors.accentPurple
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? AppSvgIcon(
                                        assetPath: AppIcons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              SizedBox(width: AppSpacing.spacingMD),
                              Expanded(
                                child: Text(
                                  widget.getTitle(item),
                                  style: AppTypography.body.copyWith(
                                    color: isSelected
                                        ? AppColors.accentPurple
                                        : textColor,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Done button
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(List<T>.from(_selectedItems)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    ),
                  ),
                  child: Text(
                    'Done (${_selectedItems.length})',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

