import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_functions/app_functions.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../home/presentation/home_screen/widgets/dot_indicator_widget.dart';

class AuctionImagesSliderWidget extends StatefulWidget {
  final List<String> images;
  final int productID;
  const AuctionImagesSliderWidget({
    super.key,
    required this.images,
    required this.productID,
  });

  @override
  State<AuctionImagesSliderWidget> createState() =>
      _AuctionImagesSliderWidgetState();
}

class _AuctionImagesSliderWidgetState extends State<AuctionImagesSliderWidget> {
  int sliderIndex = 0;

  void changeSliderIndex(int index) {
    setState(() {
      sliderIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            viewportFraction: 1,
            aspectRatio: 16 / 9,
            enlargeCenterPage: true,
            enableInfiniteScroll: widget.images.length > 1,
            initialPage: 0,
            autoPlay: widget.images.length > 1,
            onPageChanged: (index, reason) => changeSliderIndex(index),
          ),
          items: List.generate(
            widget.images.length,
            (index) => Hero(
              tag: widget.productID,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppFunctions.showImageDialog(
                      context: context,
                      imageUrl: widget.images[index],
                      id: widget.productID,
                    );
                  },
                  child: CachedNetworkImage(
                    memCacheHeight: 800,
                    fit: BoxFit.contain,
                    imageUrl: widget.images[index],
                    progressIndicatorBuilder: (context, url, progress) =>
                        Center(
                          child: CircularProgressIndicator(
                            value: progress.progress,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        gapH8,
        DotIndicatorWidget(
          currentIndex: sliderIndex,
          count: widget.images.length,
        ),
      ],
    );
  }
}
