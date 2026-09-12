import 'package:flutter/material.dart';

import '../theme/border_radius_constants.dart';
import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';
import '../utils/app_search_debounce.dart';

/// Search [TextField] that reports [onChanged] after [AppAnimations.searchDebounce].
///
/// Empty queries and [onSubmitted] flush immediately. Local rebuilds (clear
/// button) stay inside this widget so parents do not rebuild on every keystroke.
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.hintText,
    this.autofocus = false,
    this.showDefaultPrefix = true,
    this.showClearButton = true,
    this.decoration,
    this.style,
    this.textInputAction = TextInputAction.search,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;
  final bool autofocus;
  final bool showDefaultPrefix;
  final bool showClearButton;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextInputAction textInputAction;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  final AppSearchDebounce _debounce = AppSearchDebounce();
  late TextEditingController _controller;
  late bool _ownsController;
  late String _lastText;

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
  }

  @override
  void didUpdateWidget(DebouncedSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _unbindController();
      _bindController(widget.controller);
    }
  }

  void _bindController(TextEditingController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? TextEditingController();
    _lastText = _controller.text;
    _controller.addListener(_onControllerChanged);
  }

  void _unbindController() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _onControllerChanged() {
    final text = _controller.text;
    if (text == _lastText) return;
    _lastText = text;
    if (widget.showClearButton && mounted) {
      setState(() {});
    }
    _debounce.onText(text, widget.onChanged);
  }

  void _emitSubmitted(String value) {
    _debounce.flush(widget.onChanged);
    widget.onSubmitted?.call(value);
  }

  void _clear() {
    _controller.clear();
  }

  @override
  void dispose() {
    _debounce.dispose();
    _unbindController();
    super.dispose();
  }

  InputDecoration _decoration(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final base = widget.decoration ??
        InputDecoration(
          filled: true,
          fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
        );

    return base.copyWith(
      hintText: base.hintText ?? widget.hintText,
      hintStyle: base.hintStyle ??
          theme.textTheme.bodyMedium?.copyWith(color: hintColor),
      prefixIcon: base.prefixIcon ??
          (widget.showDefaultPrefix ? _defaultPrefix(context) : null),
      suffixIcon: base.suffixIcon ??
          (widget.showClearButton && _controller.text.isNotEmpty
              ? _clearButton(context)
              : null),
    );
  }

  Widget _defaultPrefix(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacingSM),
      child: AppSvgIcon(
        assetPath: AppIcons.search,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _clearButton(BuildContext context) {
    return IconButton(
      tooltip: 'Clear search',
      onPressed: _clear,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: AppSvgIcon(
        assetPath: AppIcons.close,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('debounced-search-field'),
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
      textInputAction: widget.textInputAction,
      onSubmitted: _emitSubmitted,
      decoration: _decoration(context),
    );
  }
}
