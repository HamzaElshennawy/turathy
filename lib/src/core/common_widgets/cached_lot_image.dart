import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Cached lot/catalog image with a grey placeholder for empty or failed URLs.
class CachedLotImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;

  const CachedLotImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final Widget child = url.isEmpty
        ? _placeholder()
        : CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            progressIndicatorBuilder: (context, url, progress) => Center(
              child: CircularProgressIndicator(value: progress.progress),
            ),
            errorWidget: (context, url, error) => _placeholder(),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  static Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 50),
    );
  }
}
