import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../widgets/animations/lottie_animations.dart';

/// Empty match conversation: tappable Lottie heart opener + inspiration chips.
/// Hidden by the parent as soon as the thread has any messages.
class ChatEmptyConversation extends StatelessWidget {
  const ChatEmptyConversation({
    super.key,
    this.peerName,
    this.onSendOpener,
  });

  static const String heartOpener = '❤️';

  static const List<String> inspirationOpeners = [
    'Hey 👋',
    "How's your day?",
    'Nice to match 🌈',
  ];

  final String? peerName;
  final ValueChanged<String>? onSendOpener;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = peerName != null && peerName!.trim().isNotEmpty
        ? 'Say hi to ${peerName!.trim()}'
        : 'Start the conversation';

    return ResponsiveGrid.constrained(
      context,
      Center(
        child: Padding(
          padding: ResponsivePadding.page(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PremiumTapScale(
                semanticLabel: 'Send a heart',
                onTap: onSendOpener == null
                    ? () {}
                    : () {
                        HapticFeedback.lightImpact();
                        onSendOpener!(heartOpener);
                      },
                child: SizedBox(
                  width: 148,
                  height: 148,
                  child: AppLottieAnimations.chatHeart(
                    size: 148,
                    fallback: const _BeatingHeartFallback(size: 88),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spacingMD),
              AppText(
                'You matched!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.spacingXS),
              AppText(
                greeting,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              if (onSendOpener != null) ...[
                const SizedBox(height: AppSpacing.spacingLG),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.spacingSM,
                  runSpacing: AppSpacing.spacingSM,
                  children: [
                    for (final prompt in inspirationOpeners)
                      _InspirationChip(
                        label: prompt,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSendOpener!(prompt);
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InspirationChip extends StatelessWidget {
  const _InspirationChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Send: $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingLG,
              vertical: AppSpacing.spacingSM,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardBackgroundDark
                  : AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              border: Border.all(
                color: AppColors.accentViolet.withValues(alpha: 0.28),
              ),
            ),
            child: AppText(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.accentViolet,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BeatingHeartFallback extends StatefulWidget {
  const _BeatingHeartFallback({required this.size});

  final double size;

  @override
  State<_BeatingHeartFallback> createState() => _BeatingHeartFallbackState();
}

class _BeatingHeartFallbackState extends State<_BeatingHeartFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.animationsEnabled(context)) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Center(
        child: AppSvgIcon(
          assetPath: AppIcons.getIconBold('heart'),
          size: widget.size,
          color: AppColors.accentRose,
        ),
      ),
    );
  }
}
