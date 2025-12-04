// Router: AppRouter
// go_router configuration for declarative routing
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/splash_page.dart';
import '../pages/home_page.dart';
import '../pages/onboarding_page.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../pages/profile_wizard_page.dart';
import '../screens/onboarding/onboarding_preferences_screen.dart';
import '../pages/discovery_page.dart';
import '../pages/chat_list_page.dart';
import '../pages/chat_page.dart';
import '../pages/profile_page.dart';
import '../pages/profile_edit_page.dart';
import '../screens/discovery/profile_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../screens/blocked_users_screen.dart';
import '../features/matching/presentation/screens/matches_screen.dart';
import '../features/payments/presentation/screens/google_play_billing_test_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../core/providers/api_providers.dart';
import '../shared/services/token_storage_service.dart';
import '../shared/services/onboarding_service.dart';

/// Route names constants
class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String profileWizard = '/profile-wizard';
  static const String onboarding = '/onboarding';
  static const String onboardingPreferences = '/onboarding-preferences';
  static const String home = '/home';
  static const String discovery = '/discovery';
  static const String chatList = '/chat-list';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileDetail = '/profile-detail';
  static const String billingHistory = '/billing-history';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String blockedUsers = '/blocked-users';
  static const String matches = '/matches';
  static const String googlePlayBillingTest = '/google-play-billing-test';
}

// Note: Route guards are implemented as redirect functions in individual routes
// This allows access to Riverpod providers through the ref parameter

/// App Router Configuration
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      // Global redirect logic - check authentication for protected routes
      final tokenStorage = ref.read(tokenStorageServiceProvider);
      final isAuthenticated = await tokenStorage.isAuthenticated();
      
      // List of public routes that don't require authentication
      final publicRoutes = [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.emailVerification,
      ];
      
      // If route is public, allow access
      if (publicRoutes.contains(state.uri.path)) {
        return null;
      }
      
      // For all other routes, require authentication
      if (!isAuthenticated) {
        return AppRoutes.welcome;
      }
      
      return null;
    },
    routes: [
      // Splash Screen (no guard)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Welcome Screen (no guard - public)
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      
      // Login Screen (no guard - public)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Register Screen (no guard - public)
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Email Verification Screen (no guard - public, but requires email param)
      GoRoute(
        path: AppRoutes.emailVerification,
        name: 'email-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final isNewUser = state.uri.queryParameters['isNewUser'] == 'true';
          return EmailVerificationScreen(
            email: email,
            isNewUser: isNewUser,
          );
        },
      ),
      
      // Profile Wizard (requires auth, but not profile completion)
      GoRoute(
        path: AppRoutes.profileWizard,
        name: 'profile-wizard',
        builder: (context, state) {
          final firstName = state.uri.queryParameters['firstName'] ?? '';
          return ProfileWizardPage(initialFirstName: firstName.isNotEmpty ? firstName : null);
        },
        redirect: (context, state) async {
          // Access providers through ref in the provider scope
          final tokenStorage = ref.read(tokenStorageServiceProvider);
          final isAuthenticated = await tokenStorage.isAuthenticated();
          
          if (!isAuthenticated) {
            return AppRoutes.welcome;
          }
          return null;
        },
      ),
      
      // Onboarding Screen (requires auth and profile completion)
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
        redirect: (context, state) async {
          // Access providers through ref in the provider scope
          final tokenStorage = ref.read(tokenStorageServiceProvider);
          final isAuthenticated = await tokenStorage.isAuthenticated();
          
          if (!isAuthenticated) {
            return AppRoutes.welcome;
          }
          return null;
        },
      ),
      
      // Onboarding Preferences Screen (requires auth and profile completion)
      GoRoute(
        path: AppRoutes.onboardingPreferences,
        name: 'onboarding-preferences',
        builder: (context, state) => const OnboardingPreferencesScreen(),
        redirect: (context, state) async {
          // Access providers through ref in the provider scope
          final tokenStorage = ref.read(tokenStorageServiceProvider);
          final isAuthenticated = await tokenStorage.isAuthenticated();
          
          if (!isAuthenticated) {
            return AppRoutes.welcome;
          }
          return null;
        },
      ),
      
      // Home Page (requires auth - onboarding is optional and can be done later)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
        redirect: (context, state) async {
          // Access providers through ref in the provider scope
          final tokenStorage = ref.read(tokenStorageServiceProvider);

          final isAuthenticated = await tokenStorage.isAuthenticated();
          if (!isAuthenticated) {
            return AppRoutes.welcome;
          }

          // Allow access to home even if onboarding isn't completed
          // Users can complete onboarding later from within the app
          return null;
        },
        routes: [
          // Discovery Tab (inherits auth from parent)
          GoRoute(
            path: 'discovery',
            name: 'discovery',
            builder: (context, state) => const DiscoveryPage(),
          ),

          // Chat List Tab (inherits auth from parent)
          GoRoute(
            path: 'chat-list',
            name: 'chat-list',
            builder: (context, state) => const ChatListPage(),
          ),

          // Notifications Tab (inherits auth from parent)
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),

          // Profile Tab (inherits auth from parent)
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'];
              return ProfilePage(
                userId: userId != null ? int.tryParse(userId) : null,
              );
            },
          ),
          
          // Settings (inherits auth from parent)
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          
          // Notifications (inherits auth from parent)
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          
          // Blocked Users (inherits auth from parent)
          GoRoute(
            path: 'blocked-users',
            name: 'blocked-users',
            builder: (context, state) => const BlockedUsersScreen(),
          ),
          
          // Matches (inherits auth from parent)
          GoRoute(
            path: 'matches',
            name: 'matches',
            builder: (context, state) => const MatchesScreen(),
          ),

          // Google Play Billing Test (inherits auth from parent)
          GoRoute(
            path: 'google-play-billing-test',
            name: 'google-play-billing-test',
            builder: (context, state) => const GooglePlayBillingTestScreen(),
          ),
        ],
      ),
      
      // Profile Edit (requires auth)
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile-edit',
        builder: (context, state) => const ProfileEditPage(),
        redirect: (context, state) async {
          // Access providers through ref in the provider scope
          final tokenStorage = ref.read(tokenStorageServiceProvider);
          final isAuthenticated = await tokenStorage.isAuthenticated();
          
          if (!isAuthenticated) {
            return AppRoutes.welcome;
          }
          return null;
        },
      ),
      
      // Profile Detail (requires auth)
      GoRoute(
        path: AppRoutes.profileDetail,
        name: 'profile-detail',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          if (userId == null) {
            // Invalid - redirect to home
            return const HomePage();
          }
          return ProfileDetailScreen(
            userId: int.parse(userId),
          );
        },
        redirect: (context, state) async {
          // Access providers through ref in the provider scope
          final tokenStorage = ref.read(tokenStorageServiceProvider);
          final isAuthenticated = await tokenStorage.isAuthenticated();
          
          if (!isAuthenticated) {
            return AppRoutes.welcome;
          }
          return null;
        },
      ),

      // Billing History (requires auth)
      GoRoute(
        path: AppRoutes.billingHistory,
        name: 'billing-history',
        builder: (context, state) => const BillingHistoryScreen(),
        redirect: (context, state) async {
          // Access providers through ref in the provider scope
          final tokenStorage = ref.read(tokenStorageServiceProvider);
          final isAuthenticated = await tokenStorage.isAuthenticated();

          if (!isAuthenticated) {
            return AppRoutes.welcome;
          }
          return null;
        },
      ),

      // Chat Page (requires auth)
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          final userName = state.uri.queryParameters['userName'];
          final avatarUrl = state.uri.queryParameters['avatarUrl'];
          
          if (userId == null) {
            // Invalid - redirect to chat list
            return const ChatListPage();
          }
          
          return ChatPage(
            userId: int.parse(userId),
            userName: userName,
            avatarUrl: avatarUrl,
          );
        },
        redirect: (context, state) async {
          // Access providers through ref in the provider scope
          final tokenStorage = ref.read(tokenStorageServiceProvider);
          final isAuthenticated = await tokenStorage.isAuthenticated();
          
          if (!isAuthenticated) {
            return AppRoutes.welcome;
          }
          return null;
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
