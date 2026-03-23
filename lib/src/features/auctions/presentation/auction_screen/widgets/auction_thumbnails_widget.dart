import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';

class AuctionThumbnailsWidget extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AuctionThumbnailsWidget({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Optionally return empty if length <= 1
    if (images.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: images.length,
        separatorBuilder: (context, index) => gapW8,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: currentIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
