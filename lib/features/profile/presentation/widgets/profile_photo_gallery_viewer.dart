import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../core/cache/image_cache_service.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_icons.dart';

/// Full-screen, pinch-zoom, swipeable profile photo gallery.
class ProfilePhotoGalleryViewer extends StatefulWidget {
  const ProfilePhotoGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    final urls = imageUrls.where((url) => url.isNotEmpty).toList();
    if (urls.isEmpty) return Future.value();

    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePhotoGalleryViewer(
          imageUrls: urls,
          initialIndex: initialIndex.clamp(0, urls.length - 1),
        ),
      ),
    );
  }

  @override
  State<ProfilePhotoGalleryViewer> createState() =>
      _ProfilePhotoGalleryViewerState();
}

class _ProfilePhotoGalleryViewerState extends State<ProfilePhotoGalleryViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppSvgIcon(
            assetPath: AppIcons.close,
            size: 24,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText(
          '${_index + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.imageUrls.length,
        pageController: _pageController,
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        onPageChanged: (index) => setState(() => _index = index),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: lgbtfinderCachedImageProvider(widget.imageUrls[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'profile_gallery_${widget.imageUrls[index]}',
            ),
          );
        },
        loadingBuilder: (context, event) => const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ),
      ),
    );
  }
}
