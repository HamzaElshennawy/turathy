import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DotIndicatorWidget extends StatelessWidget {
  final int currentIndex;
  final int count;
  final IndicatorEffect? effect;

  const DotIndicatorWidget(
      {super.key,
      required this.currentIndex,
      required this.count,
      this.effect});

  @override
  Widget build(BuildContext context) {
    return AnimatedSmoothIndicator(
      activeIndex: currentIndex,
      count: count,
      effect: effect ??
          WormEffect(
            activeDotColor: Theme.of(context).primaryColor,
            dotColor: Theme.of(context).primaryColor.withOpacity(0.5),
            type: WormType.underground,
            dotWidth: 8,
            dotHeight: 8,
            strokeWidth: 8,
            spacing: 6,
          ),
    );
  }
}
