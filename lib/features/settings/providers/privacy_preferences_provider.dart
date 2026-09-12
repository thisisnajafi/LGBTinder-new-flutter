import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../data/models/privacy_settings.dart';
import 'settings_provider.dart';

class PrivacyPreferencesUiState {
  const PrivacyPreferencesUiState({
    this.settings,
    this.isLoading = false,
    this.saveError,
  });

  final PrivacySettings? settings;
  final bool isLoading;
  final String? saveError;

  PrivacyPreferencesUiState copyWith({
    PrivacySettings? settings,
    bool? isLoading,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return PrivacyPreferencesUiState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }
}

final privacyPreferencesProvider =
    NotifierProvider<PrivacyPreferencesNotifier, PrivacyPreferencesUiState>(
  PrivacyPreferencesNotifier.new,
);

class PrivacyPreferencesNotifier extends Notifier<PrivacyPreferencesUiState> {
  Timer? _debounce;
  PrivacySettings? _lastSaved;

  @override
  PrivacyPreferencesUiState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      unawaited(_flushPending());
    });
    Future.microtask(reload);
    return const PrivacyPreferencesUiState(isLoading: true);
  }

  Future<void> reload() async {
    state = state.copyWith(isLoading: true, clearSaveError: true);
    try {
      final loaded =
          await ref.read(settingsServiceProvider).getPrivacySettings();
      _lastSaved = loaded;
      state = PrivacyPreferencesUiState(settings: loaded);
      ref.read(settingsProvider.notifier).hydratePrivacy(loaded);
      AppLogger.info('Loaded privacy settings', tag: 'PrivacyPrefs');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load privacy settings',
        tag: 'PrivacyPrefs',
        error: e,
        stackTrace: stack,
      );
      state = PrivacyPreferencesUiState(
        settings: state.settings ?? PrivacySettings(),
        saveError: e.toString(),
      );
    }
  }

  void patch(PrivacySettings Function(PrivacySettings) updater) {
    final current = state.settings;
    if (current == null) return;
    _lastSaved ??= current;
    final next = updater(current);
    state = PrivacyPreferencesUiState(settings: next);
    ref.read(settingsProvider.notifier).hydratePrivacy(next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_flushPending());
    });
  }

  Future<void> _flushPending() async {
    final pending = state.settings;
    if (pending == null) return;
    if (_lastSaved != null && _samePayload(pending, _lastSaved!)) return;

    try {
      final saved = await ref
          .read(settingsServiceProvider)
          .updatePrivacySettings(UpdatePrivacySettingsRequest(settings: pending));
      _lastSaved = saved;
      if (state.settings == pending) {
        state = PrivacyPreferencesUiState(settings: saved);
      }
      ref.read(settingsProvider.notifier).hydratePrivacy(_lastSaved ?? saved);
      AppLogger.info('Saved privacy settings', tag: 'PrivacyPrefs');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to save privacy settings',
        tag: 'PrivacyPrefs',
        error: e,
        stackTrace: stack,
      );
      final revert = _lastSaved;
      state = PrivacyPreferencesUiState(
        settings: revert ?? pending,
        saveError: e.toString(),
      );
      if (revert != null) {
        ref.read(settingsProvider.notifier).hydratePrivacy(revert);
      }
    }
  }

  bool _samePayload(PrivacySettings a, PrivacySettings b) {
    return a.toJson().toString() == b.toJson().toString();
  }
}
