// Widget: ChatListHeader
// Header for chat list with search
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Chat list header widget
/// Header with search bar and filter options
class ChatListHeader extends ConsumerStatefulWidget {
  final Function(String)? onSearchChanged;
  final VoidCallback? onFilterTap;
  final String? searchHint;

  const ChatListHeader({
    Key? key,
    this.onSearchChanged,
    this.onFilterTap,
    this.searchHint,
  }) : super(key: key);

  @override
  ConsumerState<ChatListHeader> createState() => _ChatListHeaderState();
}

class _ChatListHeaderState extends ConsumerState<ChatListHeader> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
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
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  widget.onSearchChanged?.call(value);
                  setState(() {
                    _isSearching = value.isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Search conversations...',
                  hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                  prefixIcon: Icon(
                    Icons.search,
                    color: secondaryTextColor,
                  ),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: secondaryTextColor,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged?.call('');
                            setState(() {
                              _isSearching = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingMD,
                  ),
                ),
                style: AppTypography.body.copyWith(color: textColor),
              ),
            ),
          ),
          if (widget.onFilterTap != null) ...[
            SizedBox(width: AppSpacing.spacingMD),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: textColor,
              ),
              onPressed: widget.onFilterTap,
            ),
          ],
        ],
      ),
    );
  }
}
