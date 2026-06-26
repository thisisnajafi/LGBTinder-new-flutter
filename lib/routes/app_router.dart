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
import '../screens/auth/password_reset_flow_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../pages/profile_wizard_page.dart';
import '../screens/onboarding/onboarding_preferences_screen.dart';
import '../features/calls/pages/outgoing_call_page.dart';
import '../pages/chat_list_page.dart';
import '../pages/chat_page.dart';
import '../pages/profile_edit_page.dart';
import '../screens/discovery/profile_detail_screen.dart';
import '../screens/blocked_users_screen.dart';
import '../features/matching/presentation/screens/matches_screen.dart';
import '../features/payments/presentation/screens/google_play_billing_test_screen.dart';
import '../features/payments/presentation/screens/subscription_plans_screen.dart' as payments;
import '../features/payments/presentation/screens/superlike_packs_screen.dart' as payments_superlikes;
import '../screens/billing_history_screen.dart';
import '../core/providers/api_providers.dart';
import '../core/providers/startup_flow_provider.dart';
import '../shared/services/token_storage_service.dart';
import '../core/utils/app_logger.dart';
import 'route_redirector.dart';
import 'home_tab_routes.dart';
import '../screens/feature_locked_screen.dart';
import '../screens/tier_comparison_screen.dart';
import '../screens/subscription_status_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/support_tickets_screen.dart';
import '../screens/legal/terms_of_service_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/banned_account_screen.dart';
import '../features/discover/presentation/screens/passport_screen.dart';
import '../features/payments/pages/subscription_management_page.dart';

/// Route names constants
class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String accountBanned = '/account-banned';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String profileWizard = '/profile-wizard';
  static const String onboarding = '/onboarding';
  static const String onboardingPreferences = '/onboarding-preferences';
  static const String home = '/home';
  static const String discovery = '/discovery';
  static const String chatList = '/chat-list';
  static const String chat = '/chat';
  static const String outgoingCall = '/call/outgoing';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileDetail = '/profile-detail';
  static const String billingHistory = '/billing-history';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String blockedUsers = '/blocked-users';
  static const String matches = '/matches';
  static const String googlePlayBillingTest = '/google-play-billing-test';
  static const String subscriptionPlans = '/subscription-plans';
  static const String superlikePacks = '/superlike-packs';
  static const String featureLocked = '/feature-locked';
  static const String tierComparison = '/tier-comparison';
  static const String subscriptionStatus = '/subscription-status';
  static const String helpSupport = '/help-support';
  static const String supportTickets = '/support-tickets';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';
  static const String subscriptionManagement = '/subscription-management';
  static const String passport = '/passport';
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

/// Instant page — use on splash so startup never waits on route transitions (ANR-safe).
Page<void> noTransitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (_, __, ___, child) => child,
  );
}

// Note: Route guards are implemented as redirect functions in individual routes
// This allows access to Riverpod providers through the ref parameter

const Set<String> _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.welcome,
  AppRoutes.accountBanned,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.emailVerification,
  AppRoutes.onboarding,
  AppRoutes.termsOfService,
  AppRoutes.privacyPolicy,
};

const Set<String> _authEntryRoutes = {
  AppRoutes.welcome,
  AppRoutes.accountBanned,
  AppRoutes.login,
  AppRoutes.register,
};

const Set<String> _authOnlyTopLevelRoutes = {
  AppRoutes.home,
  AppRoutes.profileWizard,
  AppRoutes.onboardingPreferences,
  AppRoutes.profileEdit,
  AppRoutes.profileDetail,
  AppRoutes.billingHistory,
  AppRoutes.subscriptionPlans,
  AppRoutes.chat,
  AppRoutes.outgoingCall,
  AppRoutes.featureLocked,
  AppRoutes.tierComparison,
  AppRoutes.subscriptionStatus,
  AppRoutes.helpSupport,
  AppRoutes.supportTickets,
  AppRoutes.termsOfService,
  AppRoutes.privacyPolicy,
  AppRoutes.subscriptionManagement,
};

bool _isProtectedRoute(String location) {
  if (_authOnlyTopLevelRoutes.contains(location)) return true;
  return location.startsWith('${AppRoutes.home}/');
}

enum AuthStage {
  unauthenticated,
  profileCompletion,
  authenticated,
}

class _GuardDecision {
  final String? redirectTo;
  final bool storePending;
  final bool consumePending;

  const _GuardDecision({
    this.redirectTo,
    this.storePending = false,
    this.consumePending = false,
  });
}

Future<AuthStage> _getAuthStage(TokenStorageService tokenStorage) async {
  final hasAuthToken = await tokenStorage.isAuthenticated();
  if (hasAuthToken) return AuthStage.authenticated;

  final profileToken = await tokenStorage.getProfileCompletionToken();
  if (profileToken != null && profileToken.isNotEmpty) {
    return AuthStage.profileCompletion;
  }

  return AuthStage.unauthenticated;
}

_GuardDecision evaluateGuardDecision({
  required String location,
  required bool hasLeftStartupFlow,
  required AuthStage authStage,
  required bool isPublicRoute,
  required bool isAuthEntryRoute,
  required bool isProtectedRoute,
  required bool hasPendingProtectedRoute,
}) {
  if (location == AppRoutes.splash && hasLeftStartupFlow) {
    return const _GuardDecision(redirectTo: AppRoutes.welcome);
  }

  if (isPublicRoute) {
    if (authStage == AuthStage.authenticated && isAuthEntryRoute && hasPendingProtectedRoute) {
      return const _GuardDecision(
        consumePending: true,
      );
    }
    if (authStage == AuthStage.authenticated && isAuthEntryRoute) {
      return const _GuardDecision(redirectTo: AppRoutes.home);
    }
    return const _GuardDecision();
  }

  if (authStage == AuthStage.unauthenticated && isProtectedRoute) {
    return const _GuardDecision(
      redirectTo: AppRoutes.welcome,
      storePending: true,
    );
  }

  if (authStage == AuthStage.profileCompletion && isProtectedRoute) {
    final allowedDuringCompletion = {
      AppRoutes.profileWizard,
      AppRoutes.onboardingPreferences,
    };
    if (!allowedDuringCompletion.contains(location)) {
      return const _GuardDecision(redirectTo: AppRoutes.profileWizard);
    }
  }

  return const _GuardDecision();
}

final RouteRedirector _redirector = RouteRedirector();

/// App Router Configuration
/// Redirect loop prevention: only SplashPage navigates from / to welcome or home.
/// Route-level redirects return null when already at target (see billing-history).
final appRouterProvider = Provider<GoRouter>((ref) {
  final tokenStorage = ref.read(tokenStorageServiceProvider);
  routeLog('GoRouter created, initialLocation=${AppRoutes.splash}');
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirectLimit: 5,
    observers: [_AppRouterObserver()],
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      // Splash owns auth/bootstrap; skip secure-storage reads here to avoid main-thread churn.
      if (loc == AppRoutes.splash && !hasLeftStartupFlow) {
        return null;
      }
      final legacyResolved = _redirector.resolveLegacyRoute(state.uri);
      if (legacyResolved != null && legacyResolved != state.uri.toString()) {
        routeLog('redirect: legacy ${state.uri} → $legacyResolved');
        return legacyResolved;
      }

      final authStage = await _getAuthStage(tokenStorage);
      final pending = _redirector.pendingProtectedRoute;
      final decision = evaluateGuardDecision(
        location: loc,
        hasLeftStartupFlow: hasLeftStartupFlow,
        authStage: authStage,
        isPublicRoute: _publicRoutes.contains(loc),
        isAuthEntryRoute: _authEntryRoutes.contains(loc),
        isProtectedRoute: _isProtectedRoute(loc),
        hasPendingProtectedRoute: pending != null,
      );

      if (decision.storePending) {
        _redirector.setPendingIfEmpty(state.uri.toString());
        routeLog('redirect: protected $loc without auth → ${AppRoutes.welcome}');
      }

      if (decision.consumePending && pending != null) {
        final consumed = _redirector.consumePending()!;
        routeLog('redirect: authenticated entry route $loc → pending $pending');
        return consumed;
      }

      if (decision.redirectTo != null) {
        if (decision.redirectTo == AppRoutes.profileWizard) {
          routeLog('redirect: profile-completion user from $loc → ${AppRoutes.profileWizard}');
        } else if (decision.redirectTo == AppRoutes.welcome &&
            _isProtectedRoute(loc) &&
            loc != AppRoutes.welcome) {
          routeLog('redirect: unauthenticated protected route $loc → ${AppRoutes.welcome}');
        } else if (decision.redirectTo == AppRoutes.welcome && loc == AppRoutes.splash) {
          routeLog('redirect: $loc (already left startup) → ${AppRoutes.welcome}');
        } else if (decision.redirectTo == AppRoutes.home && _authEntryRoutes.contains(loc)) {
          routeLog('redirect: authenticated user at $loc → ${AppRoutes.home}');
        }
        return decision.redirectTo;
      }

      return null;
    },
    routes: [
      // Splash Screen: checks token via GET /auth/check-token, then redirects to home or welcome
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => noTransitionPage(state, const SplashPage()),
      ),

      // Welcome Screen (no guard - public)
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => slideFadePage(state, const WelcomeScreen()),
      ),

      GoRoute(
        path: AppRoutes.accountBanned,
        name: 'account-banned',
        pageBuilder: (context, state) => slideFadePage(state, const BannedAccountScreen()),
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

      // Forgot password — full OTP reset flow (pushed from login)
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) =>
            slideFadePage(state, const PasswordResetFlowScreen()),
      ),
      
      // Email Verification Screen (no guard - public, but requires email param)
      GoRoute(
        path: AppRoutes.emailVerification,
        name: 'email-verification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final isNewUser = state.uri.queryParameters['isNewUser'] == 'true';
          final firstName = state.uri.queryParameters['firstName'];
          final lastName = state.uri.queryParameters['lastName'];
          return slideFadePage(
            state,
            EmailVerificationScreen(
              email: email,
              isNewUser: isNewUser,
              firstName: firstName,
              lastName: lastName,
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
          final lastName = state.uri.queryParameters['lastName'] ?? '';
          return slideFadePage(
            state,
            ProfileWizardPage(
              initialFirstName: firstName.isNotEmpty ? firstName : null,
              initialLastName: lastName.isNotEmpty ? lastName : null,
            ),
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
          // Main tabs live inside [HomePage]; legacy paths redirect to ?tab=.
          GoRoute(
            path: 'discovery',
            name: 'discovery',
            redirect: (_, __) => HomeTabRoutes.locationForTab(0),
          ),
          GoRoute(
            path: 'chat-list',
            name: 'chat-list',
            redirect: (_, __) => HomeTabRoutes.locationForTab(1),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            redirect: (_, __) => HomeTabRoutes.locationForTab(2),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            redirect: (context, state) {
              final userId = state.uri.queryParameters['userId'];
              return Uri(
                path: AppRoutes.home,
                queryParameters: {
                  'tab': '3',
                  if (userId != null && userId.isNotEmpty) 'userId': userId,
                },
              ).toString();
            },
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            redirect: (_, __) => HomeTabRoutes.locationForTab(4),
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
      ),

      // Subscription Plans (requires auth)
      GoRoute(
        path: AppRoutes.subscriptionPlans,
        name: 'subscription-plans',
        pageBuilder: (context, state) => slideFadePage(state, const payments.SubscriptionPlansScreen()),
      ),
      GoRoute(
        path: AppRoutes.superlikePacks,
        name: 'superlike-packs',
        pageBuilder: (context, state) =>
            slideFadePage(state, const payments_superlikes.SuperlikePacksScreen()),
      ),

      // Feature locked (requires auth; upsell screen)
      GoRoute(
        path: AppRoutes.featureLocked,
        name: 'feature-locked',
        pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          return slideFadePage(state, FeatureLockedScreen.fromQueryParams(qp));
        },
      ),

      // Tier comparison (requires auth; marketing/upsell)
      GoRoute(
        path: AppRoutes.tierComparison,
        name: 'tier-comparison',
        pageBuilder: (context, state) => slideFadePage(state, const TierComparisonScreen()),
      ),

      // Subscription status summary (requires auth)
      GoRoute(
        path: AppRoutes.subscriptionStatus,
        name: 'subscription-status',
        pageBuilder: (context, state) => slideFadePage(state, const SubscriptionStatusScreen()),
      ),

      // Help & Support (requires auth)
      GoRoute(
        path: AppRoutes.helpSupport,
        name: 'help-support',
        pageBuilder: (context, state) => slideFadePage(state, const HelpSupportScreen()),
      ),

      // Support tickets (requires auth)
      GoRoute(
        path: AppRoutes.supportTickets,
        name: 'support-tickets',
        pageBuilder: (context, state) =>
            slideFadePage(state, const SupportTicketsScreen()),
      ),

      // Terms of service (requires auth in-app flow)
      GoRoute(
        path: AppRoutes.termsOfService,
        name: 'terms-of-service',
        pageBuilder: (context, state) =>
            slideFadePage(state, const TermsOfServiceScreen()),
      ),

      // Privacy policy (requires auth in-app flow)
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacy-policy',
        pageBuilder: (context, state) =>
            slideFadePage(state, const PrivacyPolicyScreen()),
      ),

      // Subscription management (requires auth)
      GoRoute(
        path: AppRoutes.subscriptionManagement,
        name: 'subscription-management',
        pageBuilder: (context, state) =>
            slideFadePage(state, const SubscriptionManagementPage()),
      ),

      // Outgoing / active call (requires auth)
      GoRoute(
        path: AppRoutes.outgoingCall,
        name: 'outgoing-call',
        pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          final callId = int.tryParse(qp['callId'] ?? '') ?? 0;
          final recipientId = int.tryParse(qp['recipientId'] ?? '') ?? 0;
          final type = qp['type'] == 'video'
              ? OutgoingCallType.video
              : OutgoingCallType.voice;
          return slideFadePage(
            state,
            OutgoingCallPage(
              callId: callId,
              recipientId: recipientId,
              recipientName: qp['recipientName'] ?? 'User',
              recipientAvatarUrl: qp['avatarUrl'],
              type: type,
              isCallee: qp['callee'] == '1',
            ),
          );
        },
      ),

      // Passport — premium virtual discovery location (requires auth)
      GoRoute(
        path: AppRoutes.passport,
        name: 'passport',
        pageBuilder: (context, state) =>
            slideFadePage(state, const PassportScreen()),
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

class _AppRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.navigation(
      previousRoute?.settings.name ?? 'none',
      route.settings.name ?? 'unknown',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.navigation(
      route.settings.name ?? 'unknown',
      previousRoute?.settings.name ?? 'none',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.navigation(
      oldRoute?.settings.name ?? 'unknown',
      newRoute?.settings.name ?? 'unknown',
    );
  }
}
