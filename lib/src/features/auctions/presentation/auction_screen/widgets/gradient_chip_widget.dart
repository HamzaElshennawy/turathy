import 'package:flutter/material.dart';

class GradientChipWidget extends StatelessWidget {
  final String text;
  final Widget? icon;
  final Color color;
  final bool isReversed;

  const GradientChipWidget({
    super.key,
    required this.text,
    this.icon,
    required this.color,
    this.isReversed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        gradient: LinearGradient(
          colors: [
            if (!isReversed) Colors.black87,
            color,
            if (isReversed) Colors.black87,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 4)],
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
