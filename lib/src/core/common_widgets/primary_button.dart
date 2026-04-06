/// {@category Components}
///
/// The primary call-to-action button used across the application.
/// 
/// [PrimaryButton] serves as the standard for high-emphasis user interactions 
/// (e.g., 'Sign In', 'Place Bid', 'Confirm Order'). It enforces project-wide 
/// aesthetics including:
/// - **Consistent Height**: Fixed minimum height of 64dp for easy touch targeting.
/// - **Loading Integration**: Native support for switching from text to [LogoLoading].
/// - **SVG Asset Support**: Optional slot for trailing icons to enhance visual cues.
/// - **Interactive States**: Automatically disables interaction when [isLoading] 
///   is true or [onPressed] is null.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_sizes.dart';
import 'logo_loading.dart';

/// A robust, theme-aware button for primary user actions.
/// 
/// Wraps a [FilledButton] with custom constraints to maintain visual consistency 
/// across varying screen sizes and orientations.
class PrimaryButton extends StatelessWidget {
  /// The descriptive text displayed within the button.
  final String text;

  /// Optional relative path to an SVG asset to be displayed on the trailing edge.
  final String? svgPath;

  /// The action to perform on tap. If null, the button renders in a disabled state.
  final VoidCallback? onPressed;

  /// Whether the button is currently in an asynchronous pending state.
  /// 
  /// When true:
  /// - A [LogoLoading] spinner is shown instead of [text] and [svgPath].
  /// - User interactions are ignored to prevent duplicate submissions.
  final bool isLoading;

  /// Custom background color override. If omitted, uses [ColorScheme.primary].
  final Color? color;

  /// Optional action triggered on a long press.
  final VoidCallback? onLongPress;

  /// Creates a [PrimaryButton] with the required label and loading state.
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.isLoading,
    this.color,
    this.onLongPress,
    this.svgPath,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400, // Prevents buttons from spanning full-width on large tablets
        minHeight: 64, // Ergonomic hit area for mobile users
      ),
      child: FilledButton(
        onLongPress: onLongPress,
        // Business Logic: Prevent multiple taps during active loading
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sizes.p8),
          ),
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          textStyle: Theme.of(context).textTheme.titleMedium,
          padding: const EdgeInsets.symmetric(horizontal: Sizes.p12),
        ),
        child: isLoading
            ? const LogoLoading()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      text,
                      textAlign:
                          svgPath == null ? TextAlign.center : TextAlign.start,
                    ),
                  ),
                  if (svgPath != null) ...[
                    gapW8,
                    SvgPicture.asset(
                      svgPath!,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ]
                ],
              ),
      ),
    );
  }
}
