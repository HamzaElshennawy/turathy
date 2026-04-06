/// {@category Components}
///
/// A structural mask that defines the shape for animated shimmers.
/// 
/// [ContainerLoadingWidget] provides the physical geometry (dimensions and 
/// corner radius) that common 'skeleton' loaders are built upon. It is 
/// intended for use as the child of a [Shimmer.fromColors] widget.
library;

import 'package:flutter/material.dart';

/// The 'atom' of the shimmer system, representing a single loading block.
class ContainerLoadingWidget extends StatelessWidget {
  /// The fixed horizontal size of the loading block.
  final double width;

  /// The fixed vertical size of the loading block.
  final double height;

  /// The visual shape of the block (e.g., Circle for avatars, Rectangle for text).
  final BoxShape shape;

  /// Creates a [ContainerLoadingWidget] with the specified shape and size.
  const ContainerLoadingWidget({
    super.key,
    required this.width,
    required this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        // Enforces a standardized project-wide radius (15px) for rounded UI elements
        borderRadius: shape != BoxShape.circle ? BorderRadius.circular(15) : null,
        color: Colors.white,
      ),
    );
  }
}

