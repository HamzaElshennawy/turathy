import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget {
  final String text;
  final bool isSelected;
  final void Function() onTap;

  const FilterChipWidget(
      {super.key,
      required this.text,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isColor = text.contains('0xff');
    return InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 40,
          width: isColor ? 40 : null,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: isColor ? 0 : 16.0),
          decoration: ShapeDecoration(
            color: isColor
                ? Color(int.parse(text))
                : isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.surface,
            shape: StadiumBorder(
              side: BorderSide(
                width: isColor
                    ? isSelected
                        ? 7
                        : 1
                    : 1,
                color: isColor
                    ? Theme.of(context).colorScheme.onSurface
                    : isSelected
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          child: isColor
              ? Container()
              : Text(
                  text,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                )),
    );
  }
}
