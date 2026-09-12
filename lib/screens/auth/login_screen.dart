// Screen: LoginScreen
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_device_name.dart';
import '../../core/widgets/auth_page_scaffold.dart';
import '../../features/auth/data/models/email_verification_required_exception.dart';
import '../../features/auth/data/models/login_request.dart';
import '../../features/auth/presentation/widgets/login_form.dart';
import '../../features/auth/presentation/widgets/social_login_button.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../routes/app_router.dart';
import '../../shared/analytics/app_event_tracker.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../widgets/buttons/gradient_button.dart';

/// Login screen - User authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _isLoading = ValueNotifier<bool>(false);
  bool _trackedView = false;

  @override
  void initState() {
    super.initState();
    unawaited(AppDeviceName.resolve());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _trackedView) return;
      _trackedView = true;
      ref.read(appEventTrackerProvider).track(
            'auth_view',
            meta: {'screen': 'login'},
          );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _isLoading.value = true;

    try {
      ref.read(appEventTrackerProvider).track(
            'auth_submit',
            meta: {'screen': 'login'},
          );
      final authService = ref.read(authServiceProvider);
      final deviceName = await AppDeviceName.resolve();

      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        deviceName: deviceName,
      );

      final response = await authService.login(request);
      await ref.read(authProvider.notifier).login(response);

      if (mounted) {
        if (response.userState == 'email_verification_required') {
          ref.read(appEventTrackerProvider).track(
                'auth_state',
                meta: {'state': 'email_verification_required'},
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your email to continue'),
              backgroundColor: AppColors.warningYellow,
            ),
          );
          final target = Uri(
            path: AppRoutes.emailVerification,
            queryParameters: {
              'email': _emailController.text.trim(),
              'isNewUser': 'false',
            },
          ).toString();
          context.push(target);
        } else if (response.userState == 'ready_for_app' ||
            response.profileCompleted) {
          ref.read(appEventTrackerProvider).track(
                'auth_success',
                meta: {'screen': 'login'},
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Login successful'),
              backgroundColor: AppColors.onlineGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          context.go(AppRoutes.home);
        } else if (response.userState == 'profile_completion_required' ||
            response.needsProfileCompletion ||
            !response.profileCompleted) {
          ref.read(appEventTrackerProvider).track(
                'auth_state',
                meta: {'state': 'profile_completion_required'},
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete your profile to continue'),
              backgroundColor: AppColors.accentPurple,
              duration: Duration(seconds: 2),
            ),
          );
          final firstName = response.firstName ?? response.user?.firstName ?? '';
          final lastName = response.user?.lastName ?? '';
          if (firstName.isNotEmpty) {
            final params = <String, String>{'firstName': firstName};
            if (lastName.trim().isNotEmpty) {
              params['lastName'] = lastName.trim();
            }
            context.go(
              Uri(
                path: AppRoutes.profileWizard,
                queryParameters: params,
              ).toString(),
            );
          } else {
            context.go(AppRoutes.profileWizard);
          }
        }
      }
    } on EmailVerificationRequiredException catch (e) {
      if (mounted) {
        _isLoading.value = true;

        try {
          final authService = ref.read(authServiceProvider);
          await authService.requestVerificationCodeForExistingUser(e.email);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Verification code sent to your email'),
                backgroundColor: AppColors.onlineGreen,
                duration: const Duration(seconds: 2),
              ),
            );

            final target = Uri(
              path: AppRoutes.emailVerification,
              queryParameters: {'email': e.email, 'isNewUser': 'false'},
            ).toString();
            context.push(target);
          }
        } catch (codeError) {
          if (mounted) {
            ErrorHandlerService.handleError(
              context,
              codeError,
              customMessage: 'Failed to send verification code',
            );
          }
        } finally {
          if (mounted) {
            _isLoading.value = false;
          }
        }
      }
    } on ApiError catch (e) {
      ref.read(appEventTrackerProvider).track(
            'auth_error',
            meta: {'screen': 'login', 'code': e.code, 'message': e.message},
          );
      if (e.code == 403 && e.responseData != null) {
        final responseData = e.responseData!;
        final nestedData = responseData['data'] as Map<String, dynamic>?;
        if (nestedData != null &&
            nestedData['user_state'] == 'email_verification_required') {
          final email =
              nestedData['email'] as String? ?? _emailController.text.trim();
          if (mounted) {
            _isLoading.value = true;

            try {
              final authService = ref.read(authServiceProvider);
              await authService.requestVerificationCodeForExistingUser(email);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Verification code sent to your email'),
                    backgroundColor: AppColors.onlineGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );

                final target = Uri(
                  path: AppRoutes.emailVerification,
                  queryParameters: {'email': email, 'isNewUser': 'false'},
                ).toString();
                context.push(target);
              }
            } catch (codeError) {
              if (mounted) {
                ErrorHandlerService.handleError(
                  context,
                  codeError,
                  customMessage: 'Failed to send verification code',
                );
              }
            } finally {
              if (mounted) {
                _isLoading.value = false;
              }
            }
          }
          return;
        }
      }

      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
        );
      }
    } catch (e) {
      ref.read(appEventTrackerProvider).track(
            'auth_exception',
            meta: {'screen': 'login', 'error': e.toString()},
          );
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Login failed',
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
      title: 'Sign In',
      subtitle: 'Welcome back',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacingLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoginCredentialsFields(
                emailController: _emailController,
                passwordController: _passwordController,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              const LoginRememberForgotRow(),
              SizedBox(height: AppSpacing.spacingXXL),
              ValueListenableBuilder<bool>(
                valueListenable: _isLoading,
                builder: (context, loading, _) {
                  return GradientButton(
                    text: 'Sign In',
                    onPressed: loading ? null : _handleLogin,
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
              const LoginSignUpFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
