import 'package:flutter/material.dart';

import '../constants/app_images/app_images.dart';

class LogoLoading extends StatefulWidget {
  final double size;
  const LogoLoading({super.key, this.size = 20});

  @override
  State<StatefulWidget> createState() => _Avatar();
}

class _Avatar extends State<LogoLoading> with TickerProviderStateMixin {
  late AnimationController _controller;
  final Tween<double> _tween = Tween(begin: 0.75, end: 2);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _tween.animate(
            CurvedAnimation(parent: _controller, curve: Curves.elasticOut)),
        child: Container(
          decoration: const ShapeDecoration(
            color: Colors.white,
            shape: CircleBorder(
              side: BorderSide(
                color: Colors.grey,
                width: 1,
              ),
            ),
          ),
          height: widget.size,
          width: widget.size,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              AppImages.logo,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
