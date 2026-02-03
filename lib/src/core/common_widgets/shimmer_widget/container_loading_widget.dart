import 'package:flutter/material.dart';

class ContainerLoadingWidget extends StatelessWidget {
  final double width;
  final double height;
  final BoxShape shape;

  const ContainerLoadingWidget(
      {super.key,
      required this.width,
      required this.height,
      this.shape = BoxShape.rectangle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          shape: shape,
          borderRadius:
              shape != BoxShape.circle ? BorderRadius.circular(15) : null,
          color: Colors.white),
    );
  }
}
