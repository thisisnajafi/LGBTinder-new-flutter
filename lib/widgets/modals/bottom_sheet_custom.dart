import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_action_bottom_sheet.dart';

/// Custom bottom sheet widget — uses the app-wide floating sheet shell.
class BottomSheetCustom extends ConsumerWidget {
  final Widget child;
  final String? title;
  final bool showCancel;

  const BottomSheetCustom({
    super.key,
    required this.child,
    this.title,
    this.showCancel = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showCancel = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (ctx) => BottomSheetCustom(
        title: title,
        showCancel: showCancel,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBottomSheetShell(
      title: title,
      showCancel: showCancel,
      body: title == null
          ? AppBottomSheetCard(child: child)
          : AppBottomSheetListBody(title: title!, child: child),
    );
  }
}
