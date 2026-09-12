import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../data/foreground_push_policy.dart';
import '../data/models/notification_preferences.dart';
import 'notification_providers.dart';

class NotificationPreferencesUiState {
  const NotificationPreferencesUiState({
    this.preferences,
    this.isLoading = false,
    this.saveError,
  });

  final NotificationPreferences? preferences;
  final bool isLoading;
  final String? saveError;

  NotificationPreferencesUiState copyWith({
    NotificationPreferences? preferences,
    bool? isLoading,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return NotificationPreferencesUiState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }
}

final notificationPreferencesProvider = NotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesUiState>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferencesUiState> {
  Timer? _debounce;
  NotificationPreferences? _lastSaved;

  @override
  NotificationPreferencesUiState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      unawaited(_flushPending());
      if (ForegroundPushPolicy.bumpUnread == _bumpUnread) {
        ForegroundPushPolicy.bumpUnread = null;
      }
    });
    ForegroundPushPolicy.bumpUnread = _bumpUnread;
    Future.microtask(reload);
    return const NotificationPreferencesUiState(isLoading: true);
  }

  void _bumpUnread() {
    final current = ref.read(unreadNotificationCountSeedProvider);
    ref.read(unreadNotificationCountSeedProvider.notifier).state =
        (current ?? 0) + 1;
  }

  void _syncForegroundPolicy(NotificationPreferences? prefs) {
    ForegroundPushPolicy.preferences = prefs;
  }

  Future<void> reload() async {
    state = state.copyWith(isLoading: true, clearSaveError: true);
    try {
      final loaded =
          await ref.read(notificationServiceProvider).getPreferences();
      _lastSaved = loaded;
      state = NotificationPreferencesUiState(preferences: loaded);
      _syncForegroundPolicy(loaded);
      AppLogger.info('Loaded notification preferences', tag: 'AlertsPrefs');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load notification preferences',
        tag: 'AlertsPrefs',
        error: e,
        stackTrace: stack,
      );
      state = NotificationPreferencesUiState(
        preferences: state.preferences ?? NotificationPreferences(),
        saveError: e.toString(),
      );
      _syncForegroundPolicy(state.preferences);
    }
  }

  void patch(NotificationPreferences Function(NotificationPreferences) updater) {
    final current = state.preferences;
    if (current == null) return;
    _lastSaved ??= current;
    state = NotificationPreferencesUiState(preferences: updater(current));
    _syncForegroundPolicy(state.preferences);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_flushPending());
    });
  }

  Future<void> _flushPending() async {
    final pending = state.preferences;
    if (pending == null) return;
    if (_lastSaved != null && _samePayload(pending, _lastSaved!)) return;

    try {
      final saved = await ref
          .read(notificationServiceProvider)
          .updatePreferences(pending);
      _lastSaved = saved;
      if (state.preferences == pending) {
        state = NotificationPreferencesUiState(preferences: saved);
        _syncForegroundPolicy(saved);
      }
      AppLogger.info('Saved notification preferences', tag: 'AlertsPrefs');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to save notification preferences',
        tag: 'AlertsPrefs',
        error: e,
        stackTrace: stack,
      );
      final revert = _lastSaved;
      state = NotificationPreferencesUiState(
        preferences: revert ?? pending,
        saveError: e.toString(),
      );
      _syncForegroundPolicy(state.preferences);
    }
  }

  bool _samePayload(NotificationPreferences a, NotificationPreferences b) {
    return a.toJson().toString() == b.toJson().toString();
  }
}
