import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';

/// Auth text field widget - reusable text input for authentication forms
class AuthTextField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final EdgeInsetsGeometry? contentPadding;

  const AuthTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.contentPadding,
  }) : super(key: key);

  @override
  ConsumerState<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends ConsumerState<AuthTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChange);

    if (widget.controller != null && widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = _hasFocus
        ? AppColors.primaryLight
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor = textColor.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          inputFormatters: widget.inputFormatters,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          style: AppTypography.bodyLarge.copyWith(color: textColor),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
            labelStyle: AppTypography.bodyMedium.copyWith(
              color: _hasFocus ? AppColors.primaryLight : textColor,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            prefixText: widget.prefixText,
            suffixText: widget.suffixText,
            prefixStyle: AppTypography.bodyMedium.copyWith(color: textColor),
            suffixStyle: AppTypography.bodyMedium.copyWith(color: textColor),
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
              borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              borderSide: BorderSide(color: AppColors.feedbackError, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              borderSide: BorderSide(color: AppColors.feedbackError, width: 2),
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingMD,
            ),
            counterStyle: AppTypography.bodySmall.copyWith(color: hintColor),
          ),
          validator: (value) {
            _errorText = widget.validator?.call(value);
            return _errorText;
          },
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
        ),

        // Error message with animation
        if (_errorText != null && _errorText!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.spacingXS),
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.feedbackError,
                ),
                SizedBox(width: AppSpacing.spacingXS),
                Expanded(
                  child: Text(
                    _errorText!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.feedbackError,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Email field - specialized auth text field for email input
class EmailField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const EmailField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      hintText: hintText ?? 'Enter your email',
      labelText: labelText ?? 'Email',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
      ],
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      prefixIcon: Icon(
        Icons.email_outlined,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}

/// Phone field - specialized auth text field for phone input
class PhoneField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const PhoneField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      hintText: hintText ?? 'Enter your phone number',
      labelText: labelText ?? 'Phone Number',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15), // Reasonable phone number limit
      ],
      validator: validator ?? _defaultPhoneValidator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      prefixIcon: Icon(
        Icons.phone_outlined,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }

  String? _defaultPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}
