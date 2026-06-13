import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';

/// Three concise value props for the welcome screen hero area.
class WelcomeValueProps extends StatefulWidget {
  const WelcomeValueProps({super.key});

  @override
  State<WelcomeValueProps> createState() => _WelcomeValuePropsState();
}

class _WelcomeValuePropsState extends State<WelcomeValueProps>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static final _items = <_ValueProp>[
    _ValueProp(
      iconPath: AppIcons.shieldTick,
      label: 'Safe space',
    ),
    _ValueProp(
      iconPath: AppIcons.heart,
      label: 'Real matches',
    ),
    _ValueProp(
      iconPath: AppIcons.user,
      label: 'For everyone',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppAnimations.animationsEnabled(context)) {
        _controller.forward();
      } else {
        _controller.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = !AppAnimations.animationsEnabled(context);

    return Semantics(
      label: 'LGBTFinder highlights: safe space, real matches, for everyone',
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_items.length, (index) {
            final animation = disableAnimations
                ? const AlwaysStoppedAnimation(1.0)
                : CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      (index * 0.12).clamp(0.0, 0.55),
                      (0.45 + index * 0.12).clamp(0.45, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  );

            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : AppSpacing.spacingMD,
              ),
              child: SizedBox(
                width: 98,
                child: _ValuePropTile(
                  item: _items[index],
                  animation: animation,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ValueProp {
  final String iconPath;
  final String label;

  _ValueProp({
    required this.iconPath,
    required this.label,
  });
}

class _ValuePropTile extends StatelessWidget {
  final _ValueProp item;
  final Animation<double> animation;

  const _ValuePropTile({
    required this.item,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingSM,
          vertical: AppSpacing.spacingMD,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              assetPath: item.iconPath,
              size: 24,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
