/// {@category Components}
///
/// A foundational layout container that enforces project-wide visual depth and framing.
/// 
/// [CustomCard] is the standardized wrapper for all dashboard items, list entries, 
/// and content blocks. It provides:
/// - **Consistent Geometry**: Fixed 16.0 border radius to match the app's 'soft' aesthetic.
/// - **Adaptive Styling**: Automatically adjusts its shadow, border opacity, and 
///   surface color based on the current [Brightness] (Dark/Light mode).
/// - **Subtle Outlines**: Implements ultra-thin, low-opacity borders to maintain 
///   structure without visual clutter.
library;

import 'package:flutter/material.dart';

/// A theme-aware card component with pre-configured spacing and elevation.
class CustomCard extends StatelessWidget {
  /// The primary UI content to be displayed within the card's boundaries.
  final Widget child;

  /// Custom internal spacing for the [child]. 
  /// 
  /// Defaults to a standard 16.0-pixel all-around padding if omitted.
  final EdgeInsetsGeometry? padding;

  /// Manual background color override. 
  /// 
  /// If null, the widget intelligently selects between [ColorScheme.surface] 
  /// and a high-opacity dark mode derivative.
  final Color? backgroundColor;

  /// The perceived elevation (z-index) of the card. 
  /// 
  /// High values increase shadow intensity. Defaults to 0 for a flat, 
  /// modern 'paper' look.
  final double elevation;

  /// Creates a [CustomCard] with standard Turathy styling.
  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: elevation,
      // Shadow strategy: Use white reflections in dark mode, black shadows in light mode.
      shadowColor: isDarkMode ? Colors.white10 : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode 
              ? theme.colorScheme.surface.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: backgroundColor ?? (isDarkMode 
          ? theme.colorScheme.surface.withOpacity(0.8)
          : theme.colorScheme.surface),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
 