import 'package:flutter/material.dart';

/// A custom page route that pairs with [Hero] animations.
///
/// The hero image flies from the source card to the destination page while
/// the rest of the destination content slides up and fades in, creating a
/// polished "expand from card" effect.
class AuctionPageRoute<T> extends PageRouteBuilder<T> {
  AuctionPageRoute({
    required WidgetBuilder builder,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Using the native page transition ensures perfect symmetry
            // between the forward and backward Hero animations.
            // A custom FadeTransition can sometimes interfere with the framework's
            // ability to smoothly extract the Hero on the forward pass.
            return const FadeUpwardsPageTransitionsBuilder().buildTransitions(
              null, // Route is not strictly needed by FadeUpwards
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
