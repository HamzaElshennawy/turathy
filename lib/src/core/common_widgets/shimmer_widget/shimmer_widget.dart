/// {@category Components}
///
/// A high-level orchestration widget for creating 'skeleton screen' loading effects.
/// 
/// [ShimmerWidget] combines the `shimmer` package's linear-gradient animation with 
/// the structural shapes provided by [ContainerLoadingWidget]. This allows for 
/// consistent, pulsing placeholders during network requests.
/// 
/// Usage:
/// ```dart
/// ShimmerWidget(width: 100, height: 20, containerShape: BoxShape.rectangle)
/// ```
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'container_loading_widget.dart';

/// A pulsing placeholder widget that mimics the shape of the upcoming data.
class ShimmerWidget extends StatelessWidget {
  /// The horizontal dimension of the placeholder.
  final double width;

  /// The vertical dimension of the placeholder.
  final double height;

  /// The geometric profile of the loading mask. Defaults to [BoxShape.rectangle].
  final BoxShape containerShape;

  /// Creates a [ShimmerWidget] with the specified dimensions and shape.
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
        // Standardized project base color for skeleton backgrounds
        baseColor: Colors.grey[400]!,
        // Bright highlight color for the moving 'shine' effect
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

