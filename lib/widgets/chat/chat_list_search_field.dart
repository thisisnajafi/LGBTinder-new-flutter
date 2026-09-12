import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/app_search_debounce.dart';
import '../../core/widgets/premium/premium_design_system.dart';

/// Animated messenger search field (CHAT-MSG-003). Height 0→56, 250ms.
class ChatListSearchField extends StatefulWidget {
  final bool visible;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClose;

  const ChatListSearchField({
    super.key,
    required this.visible,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onSubmitted,
    required this.onClose,
  });

  @override
  State<ChatListSearchField> createState() => _ChatListSearchFieldState();
}

class _ChatListSearchFieldState extends State<ChatListSearchField> {
  final FocusNode _focusNode = FocusNode();
  final AppSearchDebounce _debounce = AppSearchDebounce();

  @override
  void didUpdateWidget(ChatListSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    } else if (!widget.visible && oldWidget.visible) {
      _focusNode.unfocus();
      _debounce.cancel();
    }
  }

  @override
  void dispose() {
    _debounce.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFieldChanged(String value) {
    _debounce.onText(value, widget.onChanged);
  }

  void _onFieldSubmitted(String value) {
    _debounce.flush(widget.onChanged);
    widget.onSubmitted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumPageHeader.horizontalPadding,
        0,
        PremiumPageHeader.horizontalPadding,
        0,
      ),
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: widget.visible ? AppSpacing.spacingSM : 0,
          ),
          child: ClipRect(
            child: AnimatedContainer(
              key: const ValueKey('chat-list-search-field'),
              duration: AppAnimations.chatSearchFieldDuration(context),
              curve: AppAnimations.curveDefault,
              height: widget.visible ? AppAnimations.chatSearchFieldHeight : 0,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: AppAnimations.chatSearchFieldHeight,
                maxHeight: AppAnimations.chatSearchFieldHeight,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: _onFieldChanged,
                  onSubmitted: _onFieldSubmitted,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    prefixIcon: _MessengerSearchPrefixIcon(isDark: isDark),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 44,
                    ),
                    suffixIcon: IconButton(
                      key: const ValueKey('chat-list-search-close'),
                      tooltip: 'Close search',
                      onPressed: widget.onClose,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: AppSvgIcon(
                        assetPath: AppIcons.close,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    filled: true,
                    fillColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      borderSide: BorderSide(
                        color: AppColors.accentViolet.withValues(alpha: 0.14),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      borderSide: BorderSide(
                        color: AppColors.accentViolet.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingSM,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessengerSearchPrefixIcon extends StatelessWidget {
  const _MessengerSearchPrefixIcon({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.spacingSM),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentViolet.withValues(alpha: isDark ? 0.32 : 0.16),
              AppColors.accentPink.withValues(alpha: isDark ? 0.24 : 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentViolet
                  .withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accentViolet, AppColors.accentPink],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: AppSvgIcon(
            assetPath: AppIcons.getIconBold('search-normal'),
            size: 17,
          ),
        ),
      ),
    );
  }
}
