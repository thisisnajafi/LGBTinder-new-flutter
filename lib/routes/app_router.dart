// Router: AppRouter
// go_router configuration for declarative routing
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/animation_constants.dart';
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
import '../screens/billing_history_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../core/providers/api_providers.dart';
import '../shared/services/token_storage_service.dart';
import '../shared/services/onboarding_service.dart';
import '../core/utils/app_logger.dart';

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

/// Builds a page with slide-from-right + fade using [AppAnimations.transitionPage].
Page<void> slideFadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppAnimations.transitionPage,
    reverseTransitionDuration: AppAnimations.transitionPage,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: AppAnimations.curveDefault,
      );
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curve);
      final fade = Tween<double>(begin: 0, end: 1).animate(curve);
      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
  );
}

// Note: Route guards are implemented as redirect functions in individual routes
// This allows access to Riverpod providers through the ref parameter

/// Set to true once we've left splash (redirected to welcome or home). Prevents redirect loop:
/// any later navigation to / (e.g. back button, recreated router) redirects to welcome.
bool _hasLeftStartupFlow = false;
void markStartupFlowLeft() => _hasLeftStartupFlow = true;

/// App Router Configuration
/// Redirect loop prevention: only SplashPage navigates from / to welcome or home.
/// Route-level redirects return null when already at target (see billing-history).
final appRouterProvider = Provider<GoRouter>((ref) {
  routeLog('GoRouter created, initialLocation=${AppRoutes.splash}');
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirectLimit: 5,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == AppRoutes.splash && _hasLeftStartupFlow) {
        routeLog('redirect: $loc (already left startup) → ${AppRoutes.welcome}');
        return AppRoutes.welcome;
      }
      return null;
    },
    routes: [
      // Splash Screen: checks token via GET /auth/check-token, then redirects to home or welcome
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => slideFadePage(state, const SplashPage()),
      ),

      // Welcome Screen (no guard - public)
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => slideFadePage(state, const WelcomeScreen()),
      ),
      
      // Login Screen (no guard - public)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => slideFadePage(state, const LoginScreen()),
      ),
      
      // Register Screen (no guard - public)
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => slideFadePage(state, const RegisterScreen()),
      ),
      
      // Email Verification Screen (no guard - public, but requires email param)
      GoRoute(
        path: AppRoutes.emailVerification,
        name: 'email-verification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final isNewUser = state.uri.queryParameters['isNewUser'] == 'true';
          return slideFadePage(
            state,
            EmailVerificationScreen(
              email: email,
              isNewUser: isNewUser,
            ),
          );
        },
      ),
      
      // Profile Wizard (requires auth, but not profile completion)
      GoRoute(
        path: AppRoutes.profileWizard,
        name: 'profile-wizard',
        pageBuilder: (context, state) {
          final firstName = state.uri.queryParameters['firstName'] ?? '';
          return slideFadePage(
            state,
            ProfileWizardPage(initialFirstName: firstName.isNotEmpty ? firstName : null),
          );
        },
      ),
      
      // Onboarding Screen (requires auth and profile completion)
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => slideFadePage(state, const OnboardingPage()),
      ),
      
      // Onboarding Preferences Screen (requires auth and profile completion)
      GoRoute(
        path: AppRoutes.onboardingPreferences,
        name: 'onboarding-preferences',
        pageBuilder: (context, state) => slideFadePage(state, const OnboardingPreferencesScreen()),
      ),
      
      // Home Page (requires auth - onboarding is optional and can be done later)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => slideFadePage(state, const HomePage()),
        routes: [
          // Discovery Tab (inherits auth from parent)
          GoRoute(
            path: 'discovery',
            name: 'discovery',
            pageBuilder: (context, state) => slideFadePage(state, const DiscoveryPage()),
          ),

          // Chat List Tab (inherits auth from parent)
          GoRoute(
            path: 'chat-list',
            name: 'chat-list',
            pageBuilder: (context, state) => slideFadePage(state, const ChatListPage()),
          ),

          // Notifications Tab (inherits auth from parent)
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            pageBuilder: (context, state) => slideFadePage(state, const NotificationsScreen()),
          ),

          // Profile Tab (inherits auth from parent)
          GoRoute(
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) {
              final userId = state.uri.queryParameters['userId'];
              return slideFadePage(
                state,
                ProfilePage(
                  userId: userId != null ? int.tryParse(userId) : null,
                ),
              );
            },
          ),
          
          // Settings (inherits auth from parent)
          GoRoute(
            path: 'settings',
            name: 'settings',
            pageBuilder: (context, state) => slideFadePage(state, const SettingsScreen()),
          ),
          
          // Blocked Users (inherits auth from parent)
          GoRoute(
            path: 'blocked-users',
            name: 'blocked-users',
            pageBuilder: (context, state) => slideFadePage(state, const BlockedUsersScreen()),
          ),
          
          // Matches (inherits auth from parent)
          GoRoute(
            path: 'matches',
            name: 'matches',
            pageBuilder: (context, state) => slideFadePage(state, const MatchesScreen()),
          ),

          // Google Play Billing Test (inherits auth from parent)
          GoRoute(
            path: 'google-play-billing-test',
            name: 'google-play-billing-test',
            pageBuilder: (context, state) => slideFadePage(state, const GooglePlayBillingTestScreen()),
          ),
        ],
      ),
      
      // Profile Edit (requires auth)
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile-edit',
        pageBuilder: (context, state) => slideFadePage(state, const ProfileEditPage()),
      ),
      
      // Profile Detail (requires auth)
      GoRoute(
        path: AppRoutes.profileDetail,
        name: 'profile-detail',
        pageBuilder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          if (userId == null) {
            return slideFadePage(state, const HomePage());
          }
          return slideFadePage(
            state,
            ProfileDetailScreen(userId: int.parse(userId)),
          );
        },
      ),

      // Billing History (requires auth)
      GoRoute(
        path: AppRoutes.billingHistory,
        name: 'billing-history',
        pageBuilder: (context, state) => slideFadePage(state, const BillingHistoryScreen()),
        redirect: (context, state) async {
          if (state.matchedLocation == AppRoutes.welcome) return null;
          final tokenStorage = ref.read(tokenStorageServiceProvider);
          final isAuthenticated = await tokenStorage.isAuthenticated();
          if (!isAuthenticated) {
            routeLog('billing-history: not authenticated → ${AppRoutes.welcome}');
            return AppRoutes.welcome;
          }
          return null;
        },
      ),

      // Chat Page (requires auth)
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        pageBuilder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          final userName = state.uri.queryParameters['userName'];
          final avatarUrl = state.uri.queryParameters['avatarUrl'];
          final child = userId == null
              ? const ChatListPage()
              : ChatPage(
                  userId: int.parse(userId),
                  userName: userName,
                  avatarUrl: avatarUrl,
                );
          return slideFadePage(state, child);
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
