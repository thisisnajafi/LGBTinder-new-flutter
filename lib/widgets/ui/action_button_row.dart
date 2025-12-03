// Widget: ActionButtonRow
// Action buttons row
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../buttons/icon_button_circle.dart';

/// Action button row widget
/// Horizontal row of action buttons
class ActionButtonRow extends ConsumerWidget {
  final List<ActionButtonItem> buttons;
  final MainAxisAlignment alignment;

  const ActionButtonRow({
    Key? key,
    required this.buttons,
    this.alignment = MainAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: alignment,
      children: buttons.map((button) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
          child: IconButtonCircle(
            icon: button.icon,
            onTap: button.onTap,
            size: button.size ?? 48.0,
            backgroundColor: button.backgroundColor,
            iconColor: button.iconColor,
            isActive: button.isActive ?? false,
          ),
        );
      }).toList(),
    );
  }
}

/// Action button item model
class ActionButtonItem {
  final IconData icon;
  final VoidCallback? onTap;
  final double? size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool? isActive;

  ActionButtonItem({
    required this.icon,
    this.onTap,
    this.size,
    this.backgroundColor,
    this.iconColor,
    this.isActive,
  });
}
