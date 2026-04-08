/// {@category Presentation}
///
/// A reusable component containing buttons for third-party social authentication.
/// 
/// Currently supports Google Sign-In and provides a layout for Apple Sign-In.
/// These buttons are typically used on both the Sign-In and Sign-Up screens.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_sizes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_controller.dart';

/// Row of social login buttons (Google, Apple).
class SocialLoginButtons extends ConsumerWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Authentication
        _SocialButton(
          label: 'Google',
          icon: SvgPicture.asset(
            'assets/icons/google.svg',
            width: 24,
            height: 24,
          ),
          onTap: () {
            ref.read(authControllerProvider.notifier).signInWithGoogle();
          },
        ),
        if (Platform.isIOS) ...[
          gapW16,

          // Apple Authentication (Placeholder)
          _SocialButton(
            label: 'Apple',
            icon: SvgPicture.asset(
              'assets/icons/apple.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
            onTap: () {
              // TODO: Implement Apple Sign In
            },
          ),
        ],
      ],
    );
  }
}

/// A private helper widget for rendering a stylized social login button.
class _SocialButton extends StatelessWidget {
  /// The provider name (e.g., 'Google').
  final String label;
  
  /// The SVG icon or image representing the provider.
  final Widget icon;
  
  /// Callback triggered when the button is pressed.
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(30),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

