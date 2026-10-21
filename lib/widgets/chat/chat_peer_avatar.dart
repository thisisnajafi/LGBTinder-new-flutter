import 'package:flutter/material.dart';

import '../../core/widgets/profile_image_widget.dart';

/// Chat avatar. Official accounts with no photo use the LGBTFinder logo.
class ChatPeerAvatar extends StatelessWidget {
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

  bool get _useLogo {
    final url = imageUrl?.trim() ?? '';
    return isOfficial && url.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_useLogo) {
      return Image.asset(
        'assets/images/logo/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'LGBTFinder Team',
      );
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
