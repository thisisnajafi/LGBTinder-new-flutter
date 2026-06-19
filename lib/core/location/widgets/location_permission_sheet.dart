import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';

/// Bottom sheet explaining why location access helps discovery matching.
class LocationPermissionSheet {
  LocationPermissionSheet._();

  static Future<void> show(
    BuildContext context, {
    bool permanentlyDenied = false,
    VoidCallback? onEnable,
    VoidCallback? onUseCity,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacingLG,
              0,
              AppSpacing.spacingLG,
              AppSpacing.spacingLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: AppSvgIcon(
                    assetPath: permanentlyDenied ? AppIcons.gpsSlash : AppIcons.gps,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingMD),
                Text(
                  permanentlyDenied
                      ? 'Location access is off'
                      : 'Find people nearby',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Text(
                  permanentlyDenied
                      ? 'Enable location in system settings for accurate distance, or keep using your profile city.'
                      : 'Allow location access to see accurate distances and better nearby matches.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingLG),
                if (!permanentlyDenied && onEnable != null)
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onEnable();
                    },
                    child: const Text('Enable location'),
                  ),
                if (permanentlyDenied)
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Geolocator.openAppSettings();
                    },
                    child: const Text('Open settings'),
                  ),
                if (onUseCity != null) ...[
                  const SizedBox(height: AppSpacing.spacingSM),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onUseCity();
                    },
                    child: const Text('Use my city instead'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
