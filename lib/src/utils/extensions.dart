import 'package:flutter/material.dart';

extension HexColor on String {
  Color toColor() {
    // Ensure the string is valid
    assert(startsWith('0x') && (length == 10 || length == 8));
    return Color(int.parse(this));
  }
}

extension ColorToHex on Color {
  String toHex({bool leadingHashSign = true}) {
    return '${leadingHashSign ? '0x' : ''}${value.toRadixString(16).padLeft(8, '0')}';
  }
}
