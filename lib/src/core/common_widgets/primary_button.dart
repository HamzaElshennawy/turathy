import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_sizes.dart';
import 'logo_loading.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final String? svgPath;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final VoidCallback? onLongPress;
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
        maxWidth: 400,
        minHeight: 64,
      ),
      child: FilledButton(
        onLongPress: onLongPress,
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
