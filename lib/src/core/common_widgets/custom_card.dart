import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Card(
      elevation: elevation,
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