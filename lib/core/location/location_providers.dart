import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/api_providers.dart';
import 'data/services/location_api_service.dart';
import 'location_bootstrap.dart';
import 'location_service.dart';
import 'location_sync_service.dart';
import 'data/models/user_location.dart';
import 'safety_location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationApiServiceProvider = Provider<LocationApiService>((ref) {
  return LocationApiService(ref.watch(apiServiceProvider));
});

final locationSyncServiceProvider = Provider<LocationSyncService>((ref) {
  return LocationSyncService(
    ref: ref,
    locationService: ref.watch(locationServiceProvider),
    locationApi: ref.watch(locationApiServiceProvider),
  );
});

final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return service.getCurrentPosition();
});

final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return service.checkPermission();
});

final userLocationProvider = FutureProvider<UserLocation>((ref) async {
  return ref.watch(locationApiServiceProvider).getLocation();
});

final safetyLocationServiceProvider = Provider<SafetyLocationService>((ref) {
  return SafetyLocationService(
    locationService: ref.watch(locationServiceProvider),
    safetyApi: ref.watch(safetyApiServiceProvider),
  );
});

/// Runs discover-time location sync and optional permission prompt.
Future<void> runDiscoverLocationBootstrap(
  WidgetRef ref,
  BuildContext context,
) {
  return LocationBootstrap.syncForDiscover(ref, context);
}

/// Runs stale background sync (e.g. on home shell load).
Future<void> runStaleLocationBootstrap(WidgetRef ref) {
  return LocationBootstrap.syncIfStale(ref);
}
