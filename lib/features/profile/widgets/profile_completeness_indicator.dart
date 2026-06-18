import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_action_bottom_sheet.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../data/models/profile_completion.dart';

/// Circular profile strength indicator with optional tips sheet.
class ProfileCompletenessIndicator extends ConsumerStatefulWidget {
  final ProfileCompletion? completion;
  final VoidCallback? onTap;

  const ProfileCompletenessIndicator({
    super.key,
    this.completion,
    this.onTap,
  });

  @override
  ConsumerState<ProfileCompletenessIndicator> createState() =>
      _ProfileCompletenessIndicatorState();
}

class _ProfileCompletenessIndicatorState
    extends ConsumerState<ProfileCompletenessIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double get _percent {
    final c = widget.completion;
    if (c == null) return 0;
    if (c.isComplete) return 100;
    final missing = c.missingFields.length;
    return (100 - (missing * 12)).clamp(20, 95).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppAnimations.animationsEnabled(context)) {
        _controller.animateTo(_percent / 100, curve: Curves.easeOutCubic);
      } else {
        _controller.value = _percent / 100;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTips(BuildContext context) {
    final missing = widget.completion?.missingFields ?? [];
    AppActionBottomSheet.show<void>(
      context: context,
      showCancel: true,
      body: AppBottomSheetCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile strength',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              if (missing.isEmpty)
                Text(
                  'Your profile looks great!',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...missing.map(
                  (field) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                    child: Row(
                      children: [
                        AppSvgIcon(
                          assetPath: AppIcons.getIconPath('add-circle'),
                          size: 18,
                          color: AppColors.accentRose,
                        ),
                        SizedBox(width: AppSpacing.spacingSM),
                        Expanded(
                          child: Text(
                            'Add ${field.replaceAll('_', ' ')}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Profile ${ _percent.round()} percent complete',
      button: true,
      child: InkWell(
        onTap: widget.onTap ?? () => _showTips(context),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ArcPainter(progress: _controller.value),
                      child: Center(
                        child: Text(
                          '${(_controller.value * 100).round()}%',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPurple,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile strength',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tap for tips to improve your profile',
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;

  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = AppColors.accentPurple.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -3.14 / 2, 3.14 * 2, false, track);

    final active = Paint()
      ..shader = AppColors.brandGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -3.14 / 2, 3.14 * 2 * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => oldDelegate.progress != progress;
}
