import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _easternArabicDigits = '٠١٢٣٤٥٦٧٨٩';
const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

/// Maps ASCII, Eastern Arabic, and Persian digits to `'0'`–`'9'`. Other
/// characters are dropped (phone/OTP fields must not swallow Arabic letters
/// silently without converting typed numerals).
String normalizeToAsciiDigits(String input) {
  final buf = StringBuffer();
  for (final r in input.runes) {
    final ch = String.fromCharCode(r);
    final eastern = _easternArabicDigits.indexOf(ch);
    if (eastern >= 0) {
      buf.write(eastern);
      continue;
    }
    final persian = _persianDigits.indexOf(ch);
    if (persian >= 0) {
      buf.write(persian);
      continue;
    }
    if (r >= 0x30 && r <= 0x39) {
      buf.write(ch);
    }
  }
  return buf.toString();
}

/// Keeps only ASCII digits after normalizing Arabic/Persian numerals.
class AsciiDigitsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = normalizeToAsciiDigits(newValue.text);
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Phone, email, password, URL, and numeric keyboards stay LTR even in Arabic.
bool keyboardTypeForcesLtr(TextInputType type) {
  if (type == TextInputType.phone ||
      type == TextInputType.emailAddress ||
      type == TextInputType.visiblePassword ||
      type == TextInputType.url) {
    return true;
  }
  return type.index == TextInputType.number.index;
}

/// Name/search/multiline follow the app locale; identifiers stay LTR.
TextDirection textDirectionForField({
  required TextInputType keyboardType,
  required TextDirection localeDirection,
}) {
  if (keyboardTypeForcesLtr(keyboardType)) {
    return TextDirection.ltr;
  }
  return localeDirection;
}

/// Shows the IME for [node], including when the field already has focus
/// (Android back / tap-outside / emulator hardware keyboard hides the IME).
void showKeyboardFor(FocusNode node) {
  void show() {
    if (!node.hasFocus) {
      node.requestFocus();
    }
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  if (node.hasFocus) {
    node.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => show());
    return;
  }
  show();
}
