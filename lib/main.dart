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
import 'features/calls/providers/incoming_call_provider.dart';
import 'core/constants/api_endpoints.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/banned_handler.dart';
import 'core/auth/unauthorized_handler.dart';
import 'core/services/app_logger.dart';
import 'routes/app_router.dart';
import 'widgets/error_handling/error_boundary.dart';
import 'shared/services/push_notification_service.dart';
import 'shared/services/incoming_call_handler.dart';
import 'shared/services/deep_linking_service.dart';
import 'core/providers/feature_flags_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/cache/cache_lifecycle_listener.dart';
import 'core/widgets/startup_cache_listener.dart';
import 'core/cache/match_realtime_sync.dart';
import 'features/chat/providers/chat_pusher_providers.dart';
import 'features/chat/providers/chat_typing_providers.dart';
import 'features/chat/providers/chat_outbound_sync_provider.dart';
import 'features/chat/providers/conversation_mute_cache_provider.dart';
import 'features/chat/providers/chat_local_sync_provider.dart';
import 'features/settings/providers/sound_preferences_provider.dart';
import 'core/utils/app_logger.dart' show startupLog, authLog;

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.debug(
    'Handling background message: ${message.messageId}',
    tag: 'FCM',
  );
}

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
    if (kDebugMode) FlutterError.presentError(details);
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
  startupLog('2. Flutter bindings initialized');

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
  bool _servicesWired = false;

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
    ref.watch(matchRealtimeSyncProvider);
    ref.watch(chatPusherLifecycleProvider);
    ref.watch(chatTypingSyncProvider);
    ref.watch(incomingCallListenerProvider);
    ref.watch(messageSoundListenerProvider);
    ref.watch(soundPreferencesProvider);
    ref.watch(chatOutboundSyncProvider);
    ref.watch(conversationMuteCacheProvider);
    ref.watch(chatLocalSyncProvider);

    if (!_servicesWired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _servicesWired) return;
        _servicesWired = true;
        DeepLinkingService().initialize(router);
        BannedHandler.setCallback(() {
          authLog('403 Banned: redirecting to banned screen');
          router.go(AppRoutes.accountBanned);
        });
        UnauthorizedHandler.setCallback(() {
          authLog('401 Unauthorized: redirecting to login');
          try {
            router.go(AppRoutes.login);
            Future.microtask(() async {
              try {
                await ref.read(authProvider.notifier).logout(silent: true);
              } catch (e, stack) {
                AppLogger.warning(
                  'Silent logout after 401 failed',
                  tag: 'Auth',
                  error: e,
                );
                AppLogger.debug('Logout stack: $stack', tag: 'Auth');
              }
            });
          } catch (e, stack) {
            AppLogger.error(
              'UnauthorizedHandler callback error',
              tag: 'Auth',
              error: e,
              stackTrace: stack,
            );
          }
        });
        unawaited(CallKitService.instance.initialize(
          onAccept: (callId) =>
              ref.read(incomingCallProvider.notifier).acceptFromCallKit(callId),
          onDecline: (callId) =>
              ref.read(incomingCallProvider.notifier).rejectFromCallKit(callId),
        ));
      });
    }

    return ErrorBoundary(
      child: StartupCacheListener(
        child: CacheLifecycleListener(
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

            ErrorWidget.builder = (FlutterErrorDetails details) {
              AppLogger.error(
                'ErrorWidget builder invoked',
                tag: 'FlutterError',
                error: details.exception,
                stackTrace: details.stack,
              );
              return Material(
                color: Colors.transparent,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details.exceptionAsString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            };
            return IncomingCallHost(
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
        ),
      ),
    );
  }
}
