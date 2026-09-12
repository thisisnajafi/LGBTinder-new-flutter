import 'package:flutter/material.dart';

import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_action_bottom_sheet.dart';

/// Confirm before redialing from an inline chat call bubble.
///
/// Returns `true` only when the matching voice/video action is chosen.
Future<bool> showCallRedialConfirmSheet({
  required BuildContext context,
  required String peerName,
  required bool isVideo,
}) async {
  final result = await AppActionBottomSheet.show<bool>(
    context: context,
    title: 'Call $peerName?',
    actions: [
      AppActionSheetItem(
        iconPath: isVideo ? AppIcons.video : AppIcons.phone,
        label: isVideo ? 'Video call' : 'Voice call',
        onTap: () => Navigator.pop(context, true),
      ),
    ],
  );
  return result == true;
}
