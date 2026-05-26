import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feature_flags_provider.dart';
import 'image_cache_service.dart';
import 'user_cache_service.dart';

/// Whether the UI is showing stale/offline cached content.
final servingCachedContentProvider = StateProvider<bool>((ref) => false);

final imageCacheServiceProvider = Provider<LgbtfinderImageCacheManager>((ref) {
  return LgbtfinderImageCacheManager();
});

final userCacheServiceProvider = Provider<UserCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) {
    throw StateError('SharedPreferences not initialized');
  }
  return UserCacheService(prefs);
});
