/// {@category Components}
///
/// A high-fidelity, branded loading indicator that pulse-animates the application logo.
/// 
/// [LogoLoading] is designed to provide a premium feel during data fetching states. 
/// It uses an elastic scaling animation to create a 'heartbeat' effect, drawing 
/// attention to the brand identity while the user waits for content.
/// 
/// Animation Profile:
/// - **Duration**: 700ms per pulse cycle.
/// - **Curve**: [Curves.elasticOut] for a bouncy, organic motion.
/// - **Scaling**: Oscillates between 75% and 200% of its base size.
library;

import 'package:flutter/material.dart';

import '../constants/app_images/app_images.dart';

/// An animated avatar-style spinner that wraps the [AppImages.logo].
class LogoLoading extends StatefulWidget {
  /// The base diameter of the circular logo container. 
  /// 
  /// Note: The actual rendered size will fluctuate between [size] * 0.75 
  /// and [size] * 2.0 during the animation.
  final double size;

  /// Creates a [LogoLoading] with a default base size of 20.0.
  const LogoLoading({super.key, this.size = 20});

  @override
  State<LogoLoading> createState() => _LogoLoadingState();
}

class _LogoLoadingState extends State<LogoLoading> with TickerProviderStateMixin {
  /// Orchestrates the 700ms pulse cycle.
  late AnimationController _controller;
  
  /// Defines the dynamic scaling range.
  final Tween<double> _tween = Tween(begin: 0.75, end: 2);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    
    // Configure to oscillate indefinitely
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _tween.animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.elasticOut,
          ),
        ),
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

