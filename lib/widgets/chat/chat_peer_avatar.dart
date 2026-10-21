import 'package:flutter/material.dart';

import '../../core/widgets/profile_image_widget.dart';

/// Chat avatar. The LGBTFinder Team mark is always the full logo, centered.
class ChatPeerAvatar extends StatelessWidget {
  static const officialLogoKey = Key('official-team-logo');

  final String? imageUrl;
  final int? userId;
  final double size;
  final bool isOfficial;

  const ChatPeerAvatar({
    super.key,
    required this.size,
    this.imageUrl,
    this.userId,
    this.isOfficial = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOfficial) {
      return _OfficialLogo(size: size);
    }

    return ProfileImageWidget(
      imageUrl: imageUrl,
      userId: userId,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}

/// Full wordmark inside the circle. Cover-cropping the wide logo shows only
/// the yellow center, so the mark is contained with even padding.
class _OfficialLogo extends StatelessWidget {
  final double size;

  const _OfficialLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ChatPeerAvatar.officialLogoKey,
      width: size,
      height: size,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: EdgeInsets.all(size * 0.16),
          child: Image.asset(
            'assets/images/logo/logo.png',
            fit: BoxFit.contain,
            alignment: Alignment.center,
            semanticLabel: 'LGBTFinder Team',
          ),
        ),
      ),
    );
  }
}
