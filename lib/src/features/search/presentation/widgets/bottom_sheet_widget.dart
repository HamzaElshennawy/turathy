import 'package:flutter/material.dart';

class BottomSheetWidget extends StatelessWidget {
  final String? title;
  final Widget child;

  const BottomSheetWidget({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return SizedBox(
      height: height,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 108,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: const ShapeDecoration(
                color: Colors.grey,
                shape: StadiumBorder(),
              ),
            ),
            if (title != null) ...[
              Text(title!),
              const SizedBox(height: 16),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
