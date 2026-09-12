import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/calls/data/services/call_kit_service.dart';
import 'features/calls/presentation/widgets/incoming_call_banner.dart';
import 'widgets/chat/in_app_chat_banner.dart';
import 'core/constants/api_endpoints.dart';
import 'core/theme/app_theme.dart';
import 'core/services/app_logger.dart';
import 'core/services/connectivity_service.dart';
import 'routes/app_router.dart';
import 'widgets/error_handling/error_boundary.dart';
import 'widgets/error_handling/app_framework_error_view.dart';
import 'shared/services/push_notification_service.dart';
import 'shared/services/fcm_background_handler.dart';
import 'shared/services/incoming_call_handler.dart';
import 'core/providers/feature_flags_provider.dart';
import 'core/providers/app_motion_prefs_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/cache/cache_lifecycle_listener.dart';
import 'core/cache/image_cache_service.dart';
import 'core/widgets/startup_cache_listener.dart';
import 'core/widgets/service_lifecycle_host.dart';
import 'core/widgets/session_side_effects_host.dart';
import 'core/widgets/plan_updated_host.dart';
import 'core/utils/app_logger.dart' show startupLog;

/// Push FCM init after first paint so home (local DB) is not blocked.
/// Was 12s; local chat cache makes first home paint cheap, so 3s is enough
/// to stay off the ANR path (PERF-MAIN-003).
const Duration deferredPushInitDelay = Duration(seconds: 3);

/// Riverpod observer — logs every provider error
class _AppProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      'Provider failed: ${provider.name ?? provider.runtimeType}',
      tag: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

void main() {
  runZonedGuarded(
    () {
      unawaited(_bootstrap());
    },
    (error, stack) {
      AppLogger.fatal(
        'Unhandled zone error',
        tag: 'runZonedGuarded',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

Future<void> _bootstrap() async {
  startupLog('1. main() started');

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.fatal(
      'Flutter framework error',
      tag: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details, forceReport: true);
    }
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger.error(
      'ErrorWidget builder invoked',
      tag: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
    return AppFrameworkErrorView(details: details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.fatal(
      'Unhandled platform error',
      tag: 'PlatformDispatcher',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  ImageCacheService.applyMemoryLimits();
  ConnectivityService.instance.initialize();
  startupLog('2. Flutter bindings initialized');
  unawaited(CallKitService.instance.startListening());

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  startupLog('3. Starting Firebase initialization...');
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    startupLog('4. Firebase initialized, background handler registered');
  } catch (e, stack) {
    AppLogger.warning(
      'Firebase init failed (non-fatal)',
      tag: 'Init',
      error: e,
    );
    AppLogger.debug('Firebase init stack: $stack', tag: 'Init');
    startupLog('4. Firebase init failed (non-fatal): $e');
  }

  startupLog('5. Loading SharedPreferences...');
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    AppMotionPreferences.hydrate(prefs);
    startupLog('6. SharedPreferences loaded');
  } catch (e, stack) {
    AppLogger.error(
      'SharedPreferences init failed',
      tag: 'Init',
      error: e,
      stackTrace: stack,
    );
    prefs = null;
    startupLog('6. SharedPreferences failed: $e');
  }

  AppLogger.info('=== LGBTFinder starting ===', tag: 'Init');
  AppLogger.info('API base: ${ApiEndpoints.baseUrl}', tag: 'Init');
  AppLogger.info(
    'Environment: ${kDebugMode ? "DEBUG" : "RELEASE"}',
    tag: 'Init',
  );
  AppLogger.info('Flutter: ${Platform.operatingSystem}', tag: 'Init');

  startupLog('7. Calling runApp()...');
  runApp(
    ProviderScope(
      observers: [_AppProviderObserver()],
      overrides: prefs != null
          ? [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ]
          : [],
      child: const MyApp(),
    ),
  );
  startupLog('8. runApp() done; scheduling post-frame callback for push init');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    startupLog('9. Post-frame callback fired (first frame painted)');
    Future.delayed(deferredPushInitDelay, () {
      _initializePushInBackground();
    });
  });
}

/// Runs after first frame; must not block the UI thread.
Future<void> _initializePushInBackground() async {
  startupLog('10. Push notification init started (${deferredPushInitDelay.inSeconds}s after first frame)');
  await Future.delayed(Duration.zero);
  try {
    await PushNotificationService().initialize();
    startupLog('11. Push notification init completed');
  } catch (e, stack) {
    AppLogger.error(
      'Push notification init failed (non-fatal)',
      tag: 'Init',
      error: e,
      stackTrace: stack,
    );
    startupLog('11. Push init failed (non-fatal): $e');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.info('App started', tag: 'Lifecycle');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.info('App lifecycle: $state', tag: 'Lifecycle');
  }

  @override
  Widget build(BuildContext context) {
    startupLog('MyApp.build()');
    final router = ref.watch(appRouterProvider);
    ref.watch(appMotionPrefsProvider);

    return ErrorBoundary(
      child: MaterialApp.router(
        title: 'LGBTFinder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ref.watch(themeModeProvider),
        routerConfig: router,
        builder: (context, child) {
          if (IncomingCallHandler.hasPendingCall()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              IncomingCallHandler.processPendingCallIfAvailable(context);
            });
          }

          return SessionSideEffectsHost(
            child: ServiceLifecycleHost(
              child: StartupCacheListener(
                child: CacheLifecycleListener(
                  child: IncomingCallHost(
                    child: InAppChatBannerHost(
                      child: PlanUpdatedHost(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
