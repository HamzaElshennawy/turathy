import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'container_loading_widget.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final BoxShape containerShape;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.containerShape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[400]!,
        highlightColor: Colors.white70,
        child: ContainerLoadingWidget(
          width: width,
          height: height,
          shape: containerShape,
        ),
      ),
    );
  }
}
