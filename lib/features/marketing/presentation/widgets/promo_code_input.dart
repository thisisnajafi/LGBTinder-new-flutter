import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/campaign_model.dart';
import '../../providers/marketing_providers.dart';

/// Promo code input widget with validation
/// Part of the Marketing System Implementation (Task 3.4.3)
class PromoCodeInput extends ConsumerStatefulWidget {
  final String? productId;
  final ValueChanged<PromoValidationResult>? onValidated;
  final ValueChanged<String>? onCodeChanged;
  final bool showApplyButton;
  final String? initialCode;

  const PromoCodeInput({
    Key? key,
    this.productId,
    this.onValidated,
    this.onCodeChanged,
    this.showApplyButton = true,
    this.initialCode,
  }) : super(key: key);

  @override
  ConsumerState<PromoCodeInput> createState() => _PromoCodeInputState();
}

class _PromoCodeInputState extends ConsumerState<PromoCodeInput> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();

  bool _isValidating = false;
  PromoValidationResult? _validationResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onCodeChanged?.call(_controller.text);

    // Clear previous validation when text changes
    if (_validationResult != null || _errorMessage != null) {
      setState(() {
        _validationResult = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _validateCode() async {
    final code = _controller.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a promo code');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(marketingServiceProvider);
      final result = await service.validatePromoCode(
        code,
        productId: widget.productId,
      );

      setState(() {
        _validationResult = result;
        if (!result.isValid) {
          _errorMessage = result.message ?? 'Invalid promo code';
        }
      });

      if (result.isValid) {
        widget.onValidated?.call(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to validate code. Please try again.';
      });
    } finally {
      setState(() => _isValidating = false);
    }
  }

  void _clearCode() {
    _controller.clear();
    setState(() {
      _validationResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = _validationResult?.isValid ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  prefixIcon: Icon(
                    Icons.local_offer_outlined,
                    color: isValid
                        ? AppColors.onlineGreen
                        : _errorMessage != null
                            ? AppColors.accentRed
                            : null,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _clearCode,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isValid
                          ? AppColors.onlineGreen
                          : _errorMessage != null
                              ? AppColors.accentRed
                              : theme.colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isValid
                          ? AppColors.onlineGreen
                          : AppColors.accentPurple,
                      width: 2,
                    ),
                  ),
                  filled: isValid,
                  fillColor:
                      isValid ? AppColors.onlineGreen.withOpacity(0.1) : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _validateCode(),
              ),
            ),
            if (widget.showApplyButton) ...[
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isValidating ? null : _validateCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isValid ? AppColors.onlineGreen : AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _isValidating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isValid ? 'Applied ✓' : 'Apply'),
                ),
              ),
            ],
          ],
        ),

        // Validation result or error
        if (_validationResult != null && _validationResult!.isValid) ...[
          const SizedBox(height: 12),
          _buildSuccessMessage(theme),
        ] else if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          _buildErrorMessage(theme),
        ],
      ],
    );
  }

  Widget _buildSuccessMessage(ThemeData theme) {
    final result = _validationResult!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.onlineGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onlineGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.onlineGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promo code applied!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.onlineGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (result.discountPercentage != null &&
                    result.discountPercentage! > 0)
                  Text(
                    '${result.discountPercentage!.toInt()}% off',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onlineGreen,
                    ),
                  )
                else if (result.discountAmount != null &&
                    result.discountAmount! > 0)
                  Text(
                    '\$${result.discountAmount!.toStringAsFixed(2)} off',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onlineGreen,
                    ),
                  ),
                if (result.bonusItems != null && result.bonusItems!.isNotEmpty)
                  Text(
                    '+ Bonus: ${result.bonusItems!.join(", ")}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onlineGreen,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: AppColors.accentRed,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          _errorMessage!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.accentRed,
          ),
        ),
      ],
    );
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Compact promo code chip for displaying applied code
class PromoCodeChip extends StatelessWidget {
  final String code;
  final String? discountText;
  final VoidCallback? onRemove;

  const PromoCodeChip({
    Key? key,
    required this.code,
    this.discountText,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.onlineGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.onlineGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer,
            color: AppColors.onlineGreen,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            code,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onlineGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (discountText != null) ...[
            const SizedBox(width: 8),
            Text(
              discountText!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onlineGreen,
              ),
            ),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                color: AppColors.onlineGreen,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
