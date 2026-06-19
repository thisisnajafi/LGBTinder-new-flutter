import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/spacing_constants.dart';

/// Five-second cancellable countdown before sending an emergency alert.
class EmergencyAlertCountdownDialog extends StatefulWidget {
  const EmergencyAlertCountdownDialog({
    super.key,
    this.seconds = 5,
  });

  final int seconds;

  static Future<bool> show(BuildContext context, {int seconds = 5}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmergencyAlertCountdownDialog(seconds: seconds),
    );

    return result == true;
  }

  @override
  State<EmergencyAlertCountdownDialog> createState() =>
      _EmergencyAlertCountdownDialogState();
}

class _EmergencyAlertCountdownDialogState
    extends State<EmergencyAlertCountdownDialog> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Sending emergency alert'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your emergency contacts will be notified in $_remaining seconds.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.spacingLG),
          Text(
            '$_remaining',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
