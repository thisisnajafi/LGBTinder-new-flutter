import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/widgets/profile_image_widget.dart';

/// Full-screen profile photo, blurred, behind a call screen.
class CallBlurredBackdrop extends StatelessWidget {
  final int userId;
  final String? imageUrl;

  const CallBlurredBackdrop({
    super.key,
    required this.userId,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Transform.scale(
                scale: 1.12,
                child: SizedBox.expand(
                  child: ProfileImageWidget(
                    imageUrl: imageUrl,
                    userId: userId,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const ColoredBox(color: Color(0x99000000)),
        ],
      ),
    );
  }
}
