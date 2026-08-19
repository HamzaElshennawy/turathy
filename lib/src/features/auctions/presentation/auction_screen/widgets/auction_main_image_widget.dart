import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:turathy/src/core/common_widgets/cached_lot_image.dart';
import 'package:turathy/src/core/constants/app_functions/app_functions.dart';

class AuctionMainImageWidget extends StatelessWidget {
  final List<String> images;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onShare;
  final VoidCallback? onWatch;
  final bool isWatched;

  const AuctionMainImageWidget({
    super.key,
    required this.images,
    required this.pageController,
    required this.onPageChanged,
    this.statusLabel,
    this.statusColor,
    this.onShare,
    this.onWatch,
    this.isWatched = false,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: PageView.builder(
              controller: pageController,
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    AppFunctions.showImageDialog(
                      context: context,
                      imageUrl: images[index],
                      id: images[index].hashCode,
                      images: images,
                      initialIndex: index,
                    );
                  },
                  child: CachedLotImage(
                    imageUrl: images[index],
                    fit: BoxFit.contain,
                    memCacheWidth: 900,
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 10,
            child: CircleAvatar(
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () {
                  pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: 10,
            child: CircleAvatar(
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () {
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
          if (statusLabel != null)
            Positioned.directional(
              textDirection: ui.TextDirection.ltr,
              start: 30,
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (statusColor ?? Colors.red).withValues(alpha: 0.9),
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  statusLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          if (onShare != null || onWatch != null)
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onShare != null)
                    _OverlayIconButton(
                      key: const Key('lot_share_button'),
                      icon: Icons.ios_share_rounded,
                      onPressed: onShare!,
                    ),
                  if (onShare != null && onWatch != null)
                    const SizedBox(width: 8),
                  if (onWatch != null)
                    _OverlayIconButton(
                      key: const Key('lot_watch_button'),
                      icon: isWatched
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      onPressed: onWatch!,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OverlayIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
