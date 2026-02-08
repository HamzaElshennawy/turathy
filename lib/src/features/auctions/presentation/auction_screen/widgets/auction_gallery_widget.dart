import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:turathy/src/core/constants/app_sizes.dart';

class AuctionGalleryWidget extends StatefulWidget {
  final List<String> images;

  const AuctionGalleryWidget({super.key, required this.images});

  @override
  State<AuctionGalleryWidget> createState() => _AuctionGalleryWidgetState();
}

class _AuctionGalleryWidgetState extends State<AuctionGalleryWidget> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.images[index],
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
                      _pageController.previousPage(
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
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        gapH16,
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.images.length,
            separatorBuilder: (context, index) => gapW8,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
