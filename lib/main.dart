import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/unauthorized_handler.dart';
import 'routes/app_router.dart';
import 'widgets/error_handling/error_boundary.dart';
import 'shared/services/push_notification_service.dart';
import 'shared/services/incoming_call_handler.dart';
import 'core/providers/feature_flags_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/utils/app_logger.dart';
// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

void main() async {
  startupLog('1. main() started');
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  startupLog('2. Flutter bindings initialized');

  // Lightweight setup only on main isolate — do NOT block first frame (avoids ANR)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Firebase + background handler MUST be registered before runApp() (Firebase docs)
  startupLog('3. Starting Firebase initialization...');
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    startupLog('4. Firebase initialized, background handler registered');
  } catch (e) {
    if (kDebugMode) debugPrint('Error initializing Firebase (non-fatal): $e');
    startupLog('4. Firebase init failed (non-fatal): $e');
  }

  // SharedPreferences: fast, keep before runApp so providers can use it
  startupLog('5. Loading SharedPreferences...');
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    startupLog('6. SharedPreferences loaded');
  } catch (e) {
    if (kDebugMode) debugPrint('Error initializing SharedPreferences: $e');
    prefs = null;
    startupLog('6. SharedPreferences failed: $e');
  }

  // Run app so first frame (splash) can paint
  startupLog('7. Calling runApp()...');
  runApp(
    ProviderScope(
      overrides: prefs != null ? [
        // Provide SharedPreferences instance
        sharedPreferencesProvider.overrideWithValue(prefs),
      ] : [],
      child: const MyApp(),
    ),
  );
  startupLog('8. runApp() done; scheduling post-frame callback for push init');

  // Defer push init until 12s after first frame so Welcome is fully interactive first (avoids ANR).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    startupLog('9. Post-frame callback fired (first frame painted)');
    Future.delayed(const Duration(seconds: 12), () {
      _initializePushInBackground();
    });
  });
}

/// Runs after first frame; must not block the UI thread.
Future<void> _initializePushInBackground() async {
  startupLog('10. Push notification init started (12s after first frame)');
  await Future.delayed(Duration.zero);
  try {
    await PushNotificationService().initialize();
    startupLog('11. Push notification init completed');
  } catch (e) {
    if (kDebugMode) debugPrint('Error initializing Push (non-fatal): $e');
    startupLog('11. Push init failed (non-fatal): $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    startupLog('MyApp.build()');
    final router = ref.watch(appRouterProvider);

    UnauthorizedHandler.setCallback(() {
      authLog('401 Unauthorized: redirecting to welcome');
      try {
        router.go(AppRoutes.welcome);
        // Clear tokens/auth in background so we don't block the UI (avoids ANR)
        Future.microtask(() async {
          try {
            await ref.read(authProvider.notifier).logout(silent: true);
          } catch (_) {
            // Ignore so 401 flow never crashes the app
          }
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔐 UnauthorizedHandler callback error: $e');
        }
      }
    });

    return ErrorBoundary(
      child: MaterialApp.router(
        title: 'LGBTFinder',
        debugShowCheckedModeBanner: false,

        // Theme Configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Follows system theme

        // Router Configuration
        routerConfig: router,

        // Error Builder
        builder: (context, child) {
          // Process pending incoming call only when one exists (avoids scheduling callback on every build → ANR).
          if (IncomingCallHandler.hasPendingCall()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              IncomingCallHandler.processPendingCallIfAvailable(context);
            });
          }

          // Handle any errors during widget building
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return ErrorBoundary(
              child: Material(
                child: Container(
                  color: Colors.red,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Something went wrong',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            details.exceptionAsString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          };
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
