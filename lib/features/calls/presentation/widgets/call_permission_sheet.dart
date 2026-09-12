import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_action_bottom_sheet.dart';
import '../../../../shared/services/call_permissions.dart';

/// Explains missing mic/camera access and offers Settings when blocked.
class CallPermissionSheet {
  CallPermissionSheet._();

  static Future<void> show(
    BuildContext context, {
    required bool video,
    required bool permanentlyDenied,
  }) {
    final theme = Theme.of(context);
    final title = CallPermissionCopy.title(
      video: video,
      permanentlyDenied: permanentlyDenied,
    );
    final body = CallPermissionCopy.body(
      video: video,
      permanentlyDenied: permanentlyDenied,
    );
    final icon = video ? AppIcons.cameraSlash : AppIcons.microphoneSlash;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return AppBottomSheetShell(
          showCancel: true,
          body: AppBottomSheetCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacingLG,
                AppSpacing.spacingLG,
                AppSpacing.spacingLG,
                AppSpacing.spacingMD,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: AppSvgIcon(
                      assetPath: icon,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingMD),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge ?? AppTypography.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.spacingSM),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: (theme.textTheme.bodyMedium ?? AppTypography.bodyMedium)
                        .copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  if (permanentlyDenied) ...[
                    const SizedBox(height: AppSpacing.spacingLG),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await openAppSettings();
                      },
                      child: const Text('Open Settings'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Check/request call media permissions; show the explanation sheet on denial.
Future<bool> ensureCallMediaPermissions(
  BuildContext context, {
  required bool video,
}) async {
  final result = await CallPermissions.ensure(video: video);
  if (result == CallPermissionResult.granted) return true;
  if (context.mounted) {
    await CallPermissionSheet.show(
      context,
      video: video,
      permanentlyDenied: result == CallPermissionResult.permanentlyDenied,
    );
  }
  return false;
}
