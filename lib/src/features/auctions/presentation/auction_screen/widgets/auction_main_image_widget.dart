import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;

class AuctionMainImageWidget extends StatelessWidget {
  final List<String> images;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final String? statusLabel;
  final Color? statusColor;

  const AuctionMainImageWidget({
    super.key,
    required this.images,
    required this.pageController,
    required this.onPageChanged,
    this.statusLabel,
    this.statusColor,
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
                return Image.network(
                  images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
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
        ],
      ),
    );
  }
}
