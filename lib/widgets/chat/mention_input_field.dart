// Widget: MentionInputField
// Text input with mention support
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/app_search_debounce.dart';

/// Mention input field widget
/// Text field with @mention support and user suggestions
class MentionInputField extends ConsumerStatefulWidget {
  final String? hintText;
  final Function(String)? onTextChanged;
  final Function(String userId, String username)? onMention;
  final List<Map<String, dynamic>>? availableUsers;

  const MentionInputField({
    super.key,
    this.hintText,
    this.onTextChanged,
    this.onMention,
    this.availableUsers,
  });

  @override
  ConsumerState<MentionInputField> createState() => _MentionInputFieldState();
}

class _MentionInputFieldState extends ConsumerState<MentionInputField> {
  final TextEditingController _controller = TextEditingController();
  final AppSearchDebounce _mentionDebounce = AppSearchDebounce();
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void dispose() {
    _mentionDebounce.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    widget.onTextChanged?.call(text);

    final mentionMatch = RegExp(r'@(\w*)$').firstMatch(text);
    if (mentionMatch == null || widget.availableUsers == null) {
      _mentionDebounce.cancel();
      if (_showSuggestions || _filteredUsers.isNotEmpty) {
        setState(() {
          _showSuggestions = false;
          _filteredUsers = [];
        });
      }
      return;
    }

    _mentionDebounce.onText(mentionMatch.group(1) ?? '', _applyMentionQuery);
  }

  void _applyMentionQuery(String query) {
    if (!mounted) return;
    final users = widget.availableUsers;
    if (users == null) return;
    final needle = query.toLowerCase();
    final filtered = users
        .where((user) =>
            (user['name'] as String?)?.toLowerCase().contains(needle) ?? false)
        .take(5)
        .toList();
    setState(() {
      _filteredUsers = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _selectMention(Map<String, dynamic> user) {
    final text = _controller.text;
    final lastAt = text.lastIndexOf('@');
    if (lastAt != -1) {
      final beforeMention = text.substring(0, lastAt);
      final newText = '$beforeMention@${user['name']} ';
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
      widget.onMention?.call(user['id'] ?? 0, user['name'] ?? '');
    }
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onTextChanged,
          style: AppTypography.body.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Type a message...',
            hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
            filled: true,
            fillColor: isDark
                ? AppColors.surfaceElevatedDark
                : AppColors.surfaceElevatedLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingMD,
            ),
          ),
        ),
        if (_showSuggestions && _filteredUsers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.spacingSM),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _filteredUsers.map((user) {
                return ListTile(
                  leading: AvatarWidget(
                    imageUrl: user['avatar_url'] as String?,
                    radius: 20,
                    fallbackInitial: user['name'] as String?,
                  ),
                  title: AppText(
                    user['name'] ?? 'User',
                    style: AppTypography.body.copyWith(color: textColor),
                    maxLines: 1,
                  ),
                  onTap: () => _selectMention(user),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
