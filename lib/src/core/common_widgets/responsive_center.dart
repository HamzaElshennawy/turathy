/// {@category Components}
///
/// A collection of layout utilities for managing content readability across device sizes.
/// 
/// These widgets prevent layout stretching on ultra-wide screens (Tablets, Desktops) 
/// by enforcing a maximum horizontal constraint and centering the resulting column.
/// 
/// It includes:
/// 1. [ResponsiveCenter]: A standard [StatelessWidget] for box-based layouts.
/// 2. [ResponsiveSliverCenter]: A [Sliver] adapter for use in [CustomScrollView].
library;

import 'package:flutter/material.dart';

import '../constants/breakpoints.dart';

/// A centering container that clamps its child to a maximum horizontal width.
/// 
/// If the viewport width exceeds [maxContentWidth], the child is rendered with 
/// a fixed width and horizontally centered with gutters. Otherwise, it 
/// occupies the full available width.
class ResponsiveCenter extends StatelessWidget {
  /// The absolute horizontal limit for the child (e.g., 600.0 for tablets).
  final double maxContentWidth;

  /// Internal spacing applied between the width constraint and the [child].
  final EdgeInsetsGeometry padding;

  /// The UI content to be constrained.
  final Widget child;

  /// Creates a [ResponsiveCenter] with a default tablet-scale constraint.
  const ResponsiveCenter({
    super.key,
    this.maxContentWidth = Breakpoint.tablet,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Strategy: Use Center to relax constraints then SizedBox to tighten them.
    return Center(
      child: SizedBox(
        width: maxContentWidth,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// A sliver-based version of [ResponsiveCenter] for scrollable lists.
/// 
/// This widget wraps [ResponsiveCenter] in a [SliverToBoxAdapter], making it 
/// compatible with [CustomScrollView]. It is ideal for centering header sections 
/// or footer buttons in long scrollable views on wide displays.
class ResponsiveSliverCenter extends StatelessWidget {
  /// The absolute horizontal limit for the child (e.g., 1024.0 for desktops).
  final double maxContentWidth;

  /// Internal spacing applied within the width constraint.
  final EdgeInsetsGeometry padding;

  /// The UI content to be rendered as a sliver.
  final Widget child;

  /// Creates a [ResponsiveSliverCenter] with a default desktop-scale constraint.
  const ResponsiveSliverCenter({
    super.key,
    this.maxContentWidth = Breakpoint.desktop,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ResponsiveCenter(
        maxContentWidth: maxContentWidth,
        padding: padding,
        child: child,
      ),
    );
  }
}
