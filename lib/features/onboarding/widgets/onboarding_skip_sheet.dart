import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_action_bottom_sheet.dart';

/// Bottom sheet confirmation before skipping onboarding.
Future<bool?> showOnboardingSkipSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  return AppActionBottomSheet.show<bool>(
    context: context,
    showCancel: false,
    body: AppBottomSheetConfirmBody(
      title: 'Skip for now?',
      message:
          'You can always finish setup later in Settings. Ready to jump in?',
      primaryLabel: 'Keep Going',
      secondaryLabel: 'Skip',
      onPrimary: () => Navigator.of(context).pop(false),
      onSecondary: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(true);
      },
    ),
  );
}
