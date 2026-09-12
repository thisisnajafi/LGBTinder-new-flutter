import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/border_radius_constants.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';

/// Shared fill, radius, and borders for every text / dropdown field.
InputDecoration premiumInputDecoration(
  BuildContext context, {
  String? hintText,
  String? prefixIconPath,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
  int? maxLength,
  EdgeInsetsGeometry? contentPadding,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final secondary =
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  final borderColor =
      isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
  final fill = isDark
      ? AppColors.surfaceElevatedDark
      : AppColors.surfaceElevatedLight;
  final hint = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

  OutlineInputBorder outline([Color? color, double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      borderSide: BorderSide(color: color ?? borderColor, width: width),
    );
  }

  Widget? leading = prefixIcon;
  if (leading == null && prefixIconPath != null) {
    leading = Padding(
      padding: const EdgeInsets.all(12),
      child: AppSvgIcon(
        assetPath: prefixIconPath,
        size: 20,
        color: secondary,
      ),
    );
  }

  return InputDecoration(
    hintText: hintText,
    hintStyle: theme.textTheme.bodyMedium?.copyWith(color: hint),
    filled: true,
    fillColor: fill,
    isDense: false,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    alignLabelWithHint: true,
    errorText: errorText,
    counterText: maxLength == null ? null : '',
    contentPadding: contentPadding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingMD,
        ),
    prefixIcon: leading,
    prefixIconConstraints: leading == null
        ? null
        : const BoxConstraints(minWidth: 48, minHeight: 48),
    suffixIcon: suffixIcon,
    border: outline(),
    enabledBorder: outline(),
    disabledBorder: outline(borderColor.withValues(alpha: 0.5)),
    focusedBorder: outline(AppColors.accentViolet, 1.5),
    errorBorder: outline(AppColors.feedbackError),
    focusedErrorBorder: outline(AppColors.feedbackError, 1.5),
  );
}

InputDecorationTheme premiumInputDecorationTheme({required bool isDark}) {
  final borderColor =
      isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
  final fill = isDark
      ? AppColors.surfaceElevatedDark
      : AppColors.surfaceElevatedLight;
  final hint = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
  final label =
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  OutlineInputBorder outline([Color? color, double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      borderSide: BorderSide(color: color ?? borderColor, width: width),
    );
  }

  return InputDecorationTheme(
    filled: true,
    fillColor: fill,
    isDense: false,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    alignLabelWithHint: true,
    hintStyle: TextStyle(color: hint, fontSize: 14),
    labelStyle: TextStyle(color: label, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.spacingMD,
      vertical: AppSpacing.spacingMD,
    ),
    border: outline(),
    enabledBorder: outline(),
    disabledBorder: outline(borderColor.withValues(alpha: 0.5)),
    focusedBorder: outline(AppColors.accentViolet, 1.5),
    errorBorder: outline(AppColors.feedbackError),
    focusedErrorBorder: outline(AppColors.feedbackError, 1.5),
  );
}

/// Premium text field: caption above the box, hint inside, SVG leading icon.
class PremiumTextField extends StatefulWidget {
  const PremiumTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixIconPath,
    this.suffixIcon,
    this.obscureText = false,
    this.enableObscureToggle,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? prefixIconPath;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool? enableObscureToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late bool _obscured;

  bool get _showToggle =>
      widget.enableObscureToggle ??
      (widget.obscureText && widget.suffixIcon == null);

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(PremiumTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText && !_showToggle) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final onSurface = theme.colorScheme.onSurface;

    Widget? suffix = widget.suffixIcon;
    if (_showToggle) {
      suffix = IconButton(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        tooltip: _obscured ? 'Show password' : 'Hide password',
        icon: AppSvgIcon(
          assetPath: _obscured ? AppIcons.visibility : AppIcons.visibilityOff,
          size: 20,
          color: secondary,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }

    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.obscureText && _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.accentViolet,
      decoration: premiumInputDecoration(
        context,
        hintText: widget.hintText ?? widget.label,
        prefixIconPath: widget.prefixIconPath,
        suffixIcon: suffix,
        maxLength: widget.maxLength,
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
    );

    if (widget.label == null || widget.label!.isEmpty) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: AppSpacing.spacingSM,
          ),
          child: Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        field,
      ],
    );
  }
}
