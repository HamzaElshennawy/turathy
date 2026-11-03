import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Store product photo shown in full, letterboxed on a neutral backdrop.
class StoreProductImage extends StatelessWidget {
  const StoreProductImage({
    super.key,
    required this.imageUrl,
    this.memCacheHeight,
    this.memCacheWidth,
  });

  final String imageUrl;
  final int? memCacheHeight;
  final int? memCacheWidth;

  static const BoxFit imageFit = BoxFit.contain;

  /// Landscape stage used by product cards so a full photo is not lost in a tall well.
  static const double frameAspect = 1.15;
  static const Color backdrop = Color(0xFFF6F3EC);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const ColoredBox(
        color: backdrop,
        child: Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }

    return ColoredBox(
      color: backdrop,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: imageFit,
        memCacheHeight: memCacheHeight,
        memCacheWidth: memCacheWidth,
        progressIndicatorBuilder: (context, url, progress) => Center(
          child: CircularProgressIndicator(value: progress.progress),
        ),
        errorWidget: (context, url, error) => const ColoredBox(
          color: backdrop,
          child: Center(child: Icon(Icons.image, color: Colors.grey)),
        ),
      ),
    );
  }
}
