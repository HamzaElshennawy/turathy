import 'package:flutter/material.dart';

class BottomSheetWidget extends StatelessWidget {
  final String? title;
  final Widget child;

  const BottomSheetWidget({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          )),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            Text(
              title!,
            ),
            const SizedBox(
              height: 16,
            )
          ],
          child,
        ],
      ),
    );
  }
}
