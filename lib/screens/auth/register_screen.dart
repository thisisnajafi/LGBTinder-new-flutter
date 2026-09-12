// Screen: RegisterScreen
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_device_name.dart';
import '../../core/widgets/auth_page_scaffold.dart';
import '../../features/auth/data/models/register_request.dart';
import '../../features/auth/presentation/widgets/register_form.dart';
import '../../features/auth/presentation/widgets/social_login_button.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../routes/app_router.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../widgets/buttons/gradient_button.dart';

/// Register screen - User registration
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _isLoading = ValueNotifier<bool>(false);
  final _agreeToTerms = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    unawaited(AppDeviceName.resolve());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _isLoading.dispose();
    _agreeToTerms.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions')),
      );
      return;
    }

    _isLoading.value = true;

    try {
      final authService = ref.read(authServiceProvider);

      final request = RegisterRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      final response = await authService.register(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.emailSent
                ? 'Verification code sent to ${response.email}'
                : 'Registration successful. Please check your email.'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );

        final target = Uri(
          path: AppRoutes.emailVerification,
          queryParameters: {
            'email': response.email,
            'isNewUser': 'true',
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
          },
        ).toString();
        context.push(target);
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Registration failed',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Registration failed',
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
    return AuthPageScaffold(
      title: 'Create Account',
      subtitle: 'Join the community',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacingLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegisterCredentialsFields(
                firstNameController: _firstNameController,
                lastNameController: _lastNameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              RegisterTermsBlock(agreed: _agreeToTerms),
              SizedBox(height: AppSpacing.spacingXXL),
              ValueListenableBuilder<bool>(
                valueListenable: _isLoading,
                builder: (context, loading, _) {
                  return GradientButton(
                    text: 'Create Account',
                    onPressed: loading ? null : _handleRegister,
                    isLoading: loading,
                    isFullWidth: true,
                  );
                },
              ),
              SizedBox(height: AppSpacing.spacingLG),
              const AuthOrDivider(),
              SizedBox(height: AppSpacing.spacingLG),
              const SocialLoginButton(
                getDeviceName: AppDeviceName.resolve,
              ),
              SizedBox(height: AppSpacing.spacingLG),
              const RegisterSignInFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
