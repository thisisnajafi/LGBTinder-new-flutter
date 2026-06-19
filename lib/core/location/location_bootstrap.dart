import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'location_providers.dart';
import 'location_sync_service.dart';
import 'widgets/location_permission_sheet.dart';

/// Coordinates permission prompts and location sync for discover / app launch.
class LocationBootstrap {
  LocationBootstrap._();

  static Future<void> syncIfStale(WidgetRef ref) async {
    final sync = ref.read(locationSyncServiceProvider);
    final result = await sync.syncIfStale();
    if (_needsCityFallback(result)) {
      await sync.syncCityCentroidFallback();
    }
  }

  static Future<void> syncForDiscover(WidgetRef ref, BuildContext context) async {
    final sync = ref.read(locationSyncServiceProvider);
    final locationService = ref.read(locationServiceProvider);

    var permission = await locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await locationService.requestPermission();
    }

    if (permission == LocationPermission.deniedForever && context.mounted) {
      await LocationPermissionSheet.show(
        context,
        permanentlyDenied: true,
        onUseCity: () => sync.syncCityCentroidFallback(),
      );
      return;
    }

    final result = await sync.syncForDiscover();

    if (result == LocationSyncResult.permissionDenied && context.mounted) {
      await LocationPermissionSheet.show(
        context,
        onEnable: () async {
          final granted = await locationService.requestPermission();
          if (granted == LocationPermission.whileInUse ||
              granted == LocationPermission.always) {
            await sync.syncForDiscover();
          }
        },
        onUseCity: () => sync.syncCityCentroidFallback(),
      );
      return;
    }

    if (_needsCityFallback(result)) {
      await sync.syncCityCentroidFallback();
    }
  }

  static bool _needsCityFallback(LocationSyncResult result) {
    return result == LocationSyncResult.permissionDenied ||
        result == LocationSyncResult.permissionDeniedForever ||
        result == LocationSyncResult.positionUnavailable ||
        result == LocationSyncResult.syncFailed;
  }
}
