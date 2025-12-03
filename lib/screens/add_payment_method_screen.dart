// Screen: AddPaymentMethodScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/alert_dialog_custom.dart';

/// Add payment method screen - Add new payment method
class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends ConsumerState<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _setAsDefault = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Add payment method via API
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Success!',
          message: 'Payment method added successfully',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add payment method: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Add Payment Method',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Card Information',
                icon: Icons.credit_card,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              // Card number
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
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
                  prefixIcon: Icon(Icons.credit_card, color: secondaryTextColor),
                ),
                style: AppTypography.body.copyWith(color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  if (value.replaceAll(' ', '').length < 16) {
                    return 'Invalid card number';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingLG),
              // Expiry and CVV
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'MM/YY',
                        hintText: '12/25',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3) {
                          return 'Invalid CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.spacingLG),
              // Cardholder name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
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
                  prefixIcon: Icon(Icons.person, color: secondaryTextColor),
                ),
                style: AppTypography.body.copyWith(color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingLG),
              // Set as default
              CheckboxListTile(
                title: Text(
                  'Set as default payment method',
                  style: AppTypography.body.copyWith(color: textColor),
                ),
                value: _setAsDefault,
                onChanged: (value) {
                  setState(() {
                    _setAsDefault = value ?? false;
                  });
                },
                activeColor: AppColors.accentPurple,
              ),
              SizedBox(height: AppSpacing.spacingXXL),
              // Add button
              GradientButton(
                text: 'Add Payment Method',
                onPressed: _isLoading ? null : _handleAdd,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              Text(
                'Your payment information is secure and encrypted',
                style: AppTypography.caption.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
