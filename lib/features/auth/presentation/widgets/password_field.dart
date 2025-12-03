import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';

/// Password field widget with validation and strength indicator
class PasswordField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final bool showStrengthIndicator;
  final bool showValidationRules;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const PasswordField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.showStrengthIndicator = false,
    this.showValidationRules = false,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  }) : super(key: key);

  @override
  ConsumerState<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends ConsumerState<PasswordField> {
  late TextEditingController _controller;
  bool _obscureText = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onPasswordChanged);
    }
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _password = _controller.text;
    });
    widget.onChanged?.call(_password);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Password field
        TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          obscureText: _obscureText,
          style: AppTypography.bodyLarge.copyWith(color: textColor),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText ?? 'Enter your password',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: textColor.withValues(alpha: 0.6),
            ),
            labelStyle: AppTypography.bodyMedium.copyWith(color: textColor),
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingMD,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: textColor.withValues(alpha: 0.6),
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          validator: widget.validator ?? _defaultValidator,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
        ),

        // Password strength indicator
        if (widget.showStrengthIndicator && _password.isNotEmpty) ...[
          SizedBox(height: AppSpacing.spacingSM),
          _buildStrengthIndicator(),
        ],

        // Validation rules
        if (widget.showValidationRules) ...[
          SizedBox(height: AppSpacing.spacingSM),
          _buildValidationRules(),
        ],
      ],
    );
  }

  Widget _buildStrengthIndicator() {
    final strength = _calculatePasswordStrength(_password);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strength.percentage,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: strength.color,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingXS),
        // Strength text
        Text(
          strength.label,
          style: AppTypography.labelSmall.copyWith(
            color: strength.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildValidationRules() {
    final rules = [
      _ValidationRule(
        text: 'At least 8 characters',
        isValid: _password.length >= 8,
      ),
      _ValidationRule(
        text: 'Contains uppercase letter',
        isValid: RegExp(r'[A-Z]').hasMatch(_password),
      ),
      _ValidationRule(
        text: 'Contains lowercase letter',
        isValid: RegExp(r'[a-z]').hasMatch(_password),
      ),
      _ValidationRule(
        text: 'Contains number',
        isValid: RegExp(r'[0-9]').hasMatch(_password),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules.map((rule) => _buildValidationRule(rule)).toList(),
    );
  }

  Widget _buildValidationRule(_ValidationRule rule) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingXS),
      child: Row(
        children: [
          Icon(
            rule.isValid ? Icons.check_circle : Icons.circle,
            size: 16,
            color: rule.isValid
                ? AppColors.feedbackSuccess
                : textColor.withValues(alpha: 0.4),
          ),
          SizedBox(width: AppSpacing.spacingXS),
          Text(
            rule.text,
            style: AppTypography.bodySmall.copyWith(
              color: rule.isValid
                  ? AppColors.feedbackSuccess
                  : textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  _PasswordStrength _calculatePasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    final percentage = score / 6.0;

    if (percentage < 0.3) {
      return _PasswordStrength('Weak', AppColors.feedbackError, percentage);
    } else if (percentage < 0.6) {
      return _PasswordStrength('Fair', AppColors.feedbackWarning, percentage);
    } else if (percentage < 0.8) {
      return _PasswordStrength('Good', Colors.orange, percentage);
    } else {
      return _PasswordStrength('Strong', AppColors.feedbackSuccess, percentage);
    }
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }
}

class _PasswordStrength {
  final String label;
  final Color color;
  final double percentage;

  _PasswordStrength(this.label, this.color, this.percentage);
}

class _ValidationRule {
  final String text;
  final bool isValid;

  _ValidationRule({required this.text, required this.isValid});
}
