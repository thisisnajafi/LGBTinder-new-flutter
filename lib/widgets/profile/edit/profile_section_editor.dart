// Widget: ProfileSectionEditor
// Profile section editor
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../buttons/gradient_button.dart';
import 'profile_field_editor.dart';

/// Profile section editor widget
/// Editor for profile sections like interests, jobs, etc. with multi-select
class ProfileSectionEditor extends ConsumerStatefulWidget {
  final String sectionTitle;
  final List<String> availableOptions;
  final List<String> selectedOptions;
  final Function(List<String>)? onSave;
  final VoidCallback? onCancel;
  final bool showSearch;
  final bool autoSave;
  final int? minSelections;
  final int? maxSelections;

  const ProfileSectionEditor({
    Key? key,
    required this.sectionTitle,
    required this.availableOptions,
    this.selectedOptions = const [],
    this.onSave,
    this.onCancel,
    this.showSearch = true,
    this.autoSave = false,
    this.minSelections,
    this.maxSelections,
  }) : super(key: key);

  @override
  ConsumerState<ProfileSectionEditor> createState() => _ProfileSectionEditorState();
}

class _ProfileSectionEditorState extends ConsumerState<ProfileSectionEditor> {
  late List<String> _selectedOptions;
  late List<String> _filteredOptions;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedOptions = List.from(widget.selectedOptions);
    _filteredOptions = List.from(widget.availableOptions);
    if (widget.showSearch) {
      _searchController.addListener(_filterOptions);
    }
  }

  @override
  void didUpdateWidget(covariant ProfileSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableOptions != widget.availableOptions) {
      final query = widget.showSearch ? _searchController.text.toLowerCase() : '';
      _filteredOptions = widget.availableOptions
          .where((option) => option.toLowerCase().contains(query))
          .toList();
    }
    if (oldWidget.selectedOptions != widget.selectedOptions) {
      _selectedOptions = List.from(widget.selectedOptions);
    }
  }

  void _filterOptions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = List.from(widget.availableOptions);
      } else {
        _filteredOptions = widget.availableOptions
            .where((option) => option.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleOption(String option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        if (widget.maxSelections != null &&
            _selectedOptions.length >= widget.maxSelections!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can select up to ${widget.maxSelections} '
                '${widget.sectionTitle.toLowerCase()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _selectedOptions.add(option);
      }
      
      // Auto-save if enabled
      if (widget.autoSave && widget.onSave != null) {
        // Check minimum selections requirement
        if (widget.minSelections != null && _selectedOptions.length < widget.minSelections!) {
          // Don't save if below minimum, but don't show error on deselect
          return;
        }
        // Save immediately
        widget.onSave!(_selectedOptions);
      }
    });
  }

  @override
  void dispose() {
    if (widget.showSearch) {
      _searchController.removeListener(_filterOptions);
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.sectionTitle,
            style: AppTypography.h2.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Select ${widget.sectionTitle.toLowerCase()}',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          if (widget.showSearch) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ${widget.sectionTitle.toLowerCase()}',
                prefixIcon: Icon(
                  Icons.search,
                  color: secondaryTextColor,
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
            SizedBox(height: AppSpacing.spacingLG),
          ],
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: _filteredOptions.map((option) {
              final isSelected = _selectedOptions.contains(option);
              return GestureDetector(
                onTap: () => _toggleOption(option),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPurple.withOpacity(0.2)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPurple
                          : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.accentPurple,
                        ),
                      if (isSelected) SizedBox(width: AppSpacing.spacingXS),
                      Text(
                        option,
                        style: AppTypography.body.copyWith(
                          color: isSelected
                              ? AppColors.accentPurple
                              : textColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (!widget.autoSave) ...[
            SizedBox(height: AppSpacing.spacingXXL),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(
                      'Cancel',
                      style: AppTypography.button.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                SizedBox(width: AppSpacing.spacingMD),
                GradientButton(
                  text: 'Save',
                  onPressed: () {
                    if (widget.minSelections != null &&
                        _selectedOptions.length < widget.minSelections!) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Select at least ${widget.minSelections} '
                            '${widget.sectionTitle.toLowerCase()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    widget.onSave?.call(_selectedOptions);
                  },
                  isFullWidth: false,
                  height: 40,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
