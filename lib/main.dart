import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'widgets/error_handling/error_boundary.dart';
import 'shared/services/push_notification_service.dart';
import 'shared/services/incoming_call_handler.dart';
import 'core/providers/feature_flags_provider.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize push notifications
    await PushNotificationService().initialize();
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue app initialization even if Firebase fails
  }

  // Set preferred orientations (optional - can be configured per screen)
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Initialize SharedPreferences for feature flags
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    print('Error initializing SharedPreferences: $e');
    // Continue without SharedPreferences - app will work with limited functionality
    prefs = null;
  }

  // Run app with error boundary
  runApp(
    ProviderScope(
      overrides: prefs != null ? [
        // Provide SharedPreferences instance
        sharedPreferencesProvider.overrideWithValue(prefs),
      ] : [],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

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
          // Process any pending incoming calls
          WidgetsBinding.instance.addPostFrameCallback((_) {
            IncomingCallHandler.processPendingCallIfAvailable(context);
          });

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
