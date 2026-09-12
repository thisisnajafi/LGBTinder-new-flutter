// Screen: AddPaymentMethodScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_page_scaffold.dart';
import '../core/widgets/premium/premium_text_field.dart';
import '../widgets/common/section_header.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/alert_dialog_custom.dart';
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';

/// Add payment method screen - Add new payment method
class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  ConsumerState<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends ConsumerState<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _setAsDefault = ValueNotifier(false);

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _isLoading.dispose();
    _setAsDefault.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _isLoading.value = true;

    try {
      // TODO: Integrate with Stripe Elements to collect card details and get payment_method_id
      // For now, using a placeholder payment method ID for demonstration
      const placeholderPaymentMethodId = 'pm_card_visa'; // This would come from Stripe Elements

      final apiService = ref.read(apiServiceProvider);
      await apiService.post<Map<String, dynamic>>(
        ApiEndpoints.userPaymentMethods,
        data: {'payment_method_id': placeholderPaymentMethodId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Success!',
          message: 'Payment method added successfully',
          iconPath: AppIcons.tickCircle,
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
        _isLoading.value = false;
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

    return AppPageScaffold(
      title: 'Add Payment Method',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ResponsiveGrid.constrainedTo(
        context,
        SingleChildScrollView(
          padding: ResponsivePadding.page(context),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Card Information',
                iconPath: AppIcons.card,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              // Card number
              PremiumTextField(
                controller: _cardNumberController,
                label: 'Card number',
                hintText: '1234 5678 9012 3456',
                keyboardType: TextInputType.number,
                prefixIconPath: AppIcons.card,
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
                    child: PremiumTextField(
                      controller: _expiryController,
                      label: 'MM/YY',
                      hintText: '12/25',
                      keyboardType: TextInputType.number,
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
                    child: PremiumTextField(
                      controller: _cvvController,
                      label: 'CVV',
                      hintText: '123',
                      keyboardType: TextInputType.number,
                      obscureText: true,
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
              PremiumTextField(
                controller: _nameController,
                label: 'Cardholder name',
                hintText: 'Name on card',
                prefixIconPath: AppIcons.user,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingLG),
              // Set as default
              ValueListenableBuilder<bool>(
                valueListenable: _setAsDefault,
                builder: (context, setAsDefault, _) {
                  return CheckboxListTile(
                    title: AppText(
                      'Set as default payment method',
                      style: AppTypography.body.copyWith(color: textColor),
                      maxLines: 2,
                    ),
                    value: setAsDefault,
                    onChanged: (value) =>
                        _setAsDefault.value = value ?? false,
                    activeColor: AppColors.accentPurple,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.spacingXXL),
              ValueListenableBuilder<bool>(
                valueListenable: _isLoading,
                builder: (context, loading, _) {
                  return GradientButton(
                    text: 'Add Payment Method',
                    onPressed: loading ? null : _handleAdd,
                    isLoading: loading,
                    isFullWidth: true,
                  );
                },
              ),
              SizedBox(height: AppSpacing.spacingMD),
              AppText(
                'Your payment information is secure and encrypted',
                style: AppTypography.caption.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ],
          ),
        ),
        ),
        tablet: 500,
      ),
    );
  }
}
