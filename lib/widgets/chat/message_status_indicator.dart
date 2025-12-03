// Widget: MessageStatusIndicator
// Message read/sent status
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

/// Message read/sent status indicator widget
/// Shows single checkmark for sent, double checkmark for read
class MessageStatusIndicator extends ConsumerWidget {
  final bool isRead;

  const MessageStatusIndicator({
    Key? key,
    required this.isRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 14,
      color: isRead ? AppColors.accentPurple : Colors.white70,
    );
  }
}
