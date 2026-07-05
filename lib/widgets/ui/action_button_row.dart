// Widget: ActionButtonRow
// Action buttons row
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final row = Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final estimatedWidth = buttons.fold<double>(
          0,
          (sum, button) =>
              sum + (button.size ?? 48.0) + AppSpacing.spacingSM * 2,
        );

        if (estimatedWidth > constraints.maxWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: row,
          );
        }

        return row;
      },
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
