import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_action_bottom_sheet.dart';
import '../../features/chat/utils/chat_media_permissions.dart';

/// Explains missing camera / photos / mic access and always offers Settings.
class ChatMediaPermissionSheet {
  ChatMediaPermissionSheet._();

  static String _iconFor(ChatMediaPermissionKind kind) {
    switch (kind) {
      case ChatMediaPermissionKind.camera:
        return AppIcons.cameraSlash;
      case ChatMediaPermissionKind.microphone:
        return AppIcons.microphoneSlash;
      case ChatMediaPermissionKind.photos:
      case ChatMediaPermissionKind.videos:
        return AppIcons.gallery;
    }
  }

  static Future<void> show(
    BuildContext context, {
    required ChatMediaPermissionKind kind,
    required bool permanentlyDenied,
    Future<void> Function()? onOpenSettings,
  }) {
    final theme = Theme.of(context);
    final title = ChatMediaPermissionCopy.title(
      kind: kind,
      permanentlyDenied: permanentlyDenied,
    );
    final body = ChatMediaPermissionCopy.body(
      kind: kind,
      permanentlyDenied: permanentlyDenied,
    );

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
                      assetPath: _iconFor(kind),
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
                  const SizedBox(height: AppSpacing.spacingLG),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await (onOpenSettings ?? openAppSettings)();
                    },
                    child: const Text(ChatMediaPermissionCopy.openSettingsLabel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Check/request chat media permissions; show the explanation sheet on denial.
Future<bool> ensureChatMediaPermission(
  BuildContext context,
  ChatMediaPermissionKind kind,
) async {
  final result = await ChatMediaPermissions.ensure(kind);
  if (result == ChatMediaPermissionResult.granted) return true;
  if (context.mounted) {
    await ChatMediaPermissionSheet.show(
      context,
      kind: kind,
      permanentlyDenied: result == ChatMediaPermissionResult.permanentlyDenied,
    );
  }
  return false;
}
