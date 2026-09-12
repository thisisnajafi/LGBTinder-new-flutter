import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/utils/app_icons.dart';

/// Mic ↔ send icon with fade + 0.8→1.0 scale morph (CHAT-INPUT-001).
class ChatSendMorphIcon extends StatelessWidget {
  final bool hasText;
  final bool isEditing;
  final Color color;
  final double size;

  const ChatSendMorphIcon({
    super.key,
    required this.hasText,
    required this.color,
    this.isEditing = false,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final animate = AppAnimations.animationsEnabled(context);
    final assetPath = isEditing
        ? AppIcons.tickCircle
        : (hasText ? AppIcons.send : AppIcons.microphone);
    final keyName = isEditing ? 'check' : (hasText ? 'send' : 'mic');
    return AnimatedSwitcher(
      duration: AppAnimations.chatSendMorphDuration(context),
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (child, animation) {
        if (!animate) return child;
        final fade = CurvedAnimation(
          parent: animation,
          curve: AppAnimations.curveDefault,
        );
        final scale = Tween<double>(
          begin: AppAnimations.chatSendMorphScaleBegin,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppAnimations.chatSendMorphCurve,
          ),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: AppSvgIcon(
        key: ValueKey(keyName),
        assetPath: assetPath,
        size: size,
        color: color,
      ),
    );
  }
}
