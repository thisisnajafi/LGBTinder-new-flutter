import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/cache_invalidator.dart';
import 'data/models/passport_location.dart';
import 'data/models/user_location.dart';
import 'location_providers.dart';

/// Current passport payload from [userLocationProvider].
final passportLocationProvider = Provider<PassportLocation>((ref) {
  return ref.watch(userLocationProvider).maybeWhen(
        data: (location) => location.passport,
        orElse: () => const PassportLocation(),
      );
});

final passportControllerProvider = Provider<PassportController>((ref) {
  return PassportController(ref);
});

/// Activate or clear premium passport search location.
class PassportController {
  PassportController(this._ref);

  final Ref _ref;

  Future<UserLocation> activate({
    required int cityId,
    int durationHours = 24,
  }) async {
    final location = await _ref.read(locationApiServiceProvider).activatePassport(
          cityId: cityId,
          durationHours: durationHours,
        );
    _ref.invalidate(userLocationProvider);
    await _ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
    return location;
  }

  Future<UserLocation> clear() async {
    final location = await _ref.read(locationApiServiceProvider).clearPassport();
    _ref.invalidate(userLocationProvider);
    await _ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
    return location;
  }
}
