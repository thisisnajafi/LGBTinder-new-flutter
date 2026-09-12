import 'package:flutter/material.dart';

/// 10px online indicator with a 2px ring (CHAT-MSG-005).
///
/// Fill is the documented `#22C55E` exception — not [AppColors.onlineGreen]
/// (`#2ECC71`), which aliases success UI elsewhere.
class ChatOnlineDot extends StatelessWidget {
  static const Key dotKey = ValueKey('chat-online-dot');

  /// Documented CHAT-MSG-005 exception.
  static const Color fill = Color(0xFF22C55E);
  static const double diameter = 10;
  static const double ringWidth = 2;

  final Color ringColor;

  const ChatOnlineDot({
    super.key,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Online',
      child: Container(
        key: dotKey,
        width: diameter + ringWidth * 2,
        height: diameter + ringWidth * 2,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: ringColor,
            width: ringWidth,
          ),
        ),
      ),
    );
  }
}
