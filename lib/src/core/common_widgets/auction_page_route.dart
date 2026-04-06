/// {@category Components}
///
/// A specialized navigation transition optimized for auction-to-detail flows.
/// 
/// [AuctionPageRoute] is a custom [PageRouteBuilder] designed to work in 
/// harmony with [Hero] animations. It is typically used when navigating 
/// from a dashboard [AuctionCard] to a full [AuctionScreen].
/// 
/// Transition Logic:
/// - **Duration**: Fixed at 500ms to provide enough 'hang time' for complex Heroes 
///   to settle smoothly.
/// - **Animation**: Uses [FadeUpwardsPageTransitionsBuilder] to create a 
///   consistent, platform-agnostic 'slide and fade' appearance.
/// - **Opacity**: Set to `non-opaque` to allow underlying layers to remain 
///   partially visible during the initial frames of the flight.
library;

import 'package:flutter/material.dart';

/// A custom page route that facilitates an "expand from source" visual effect.
class AuctionPageRoute<T> extends PageRouteBuilder<T> {
  /// Creates an [AuctionPageRoute] that renders the widget from [builder].
  AuctionPageRoute({
    required WidgetBuilder builder,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          
          /// Slower duration than standard to allow the [Hero] animation time to settle.
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Strategy: Leverage the native 'FadeUpwards' builder.
            // Using a raw FadeTransition can sometimes interfere with the 
            // framework's ability to smoothly extract the Hero widget on 
            // the forward pass. This approach ensures perfect symmetry.
            return const FadeUpwardsPageTransitionsBuilder().buildTransitions(
              null, // Route context is internally managed by the builder
              context,
              animation,
              secondaryAnimation,
              child,
            );
          },
        );

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;
}
