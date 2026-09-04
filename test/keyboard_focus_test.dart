import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/keyboard_focus.dart';

void main() {
  group('keyboardTypeForcesLtr', () {
    test('keeps phone email password and number LTR', () {
      expect(keyboardTypeForcesLtr(TextInputType.phone), isTrue);
      expect(keyboardTypeForcesLtr(TextInputType.emailAddress), isTrue);
      expect(keyboardTypeForcesLtr(TextInputType.visiblePassword), isTrue);
      expect(keyboardTypeForcesLtr(TextInputType.number), isTrue);
      expect(
        keyboardTypeForcesLtr(
          const TextInputType.numberWithOptions(decimal: true),
        ),
        isTrue,
      );
    });

    test('name and text follow locale', () {
      expect(keyboardTypeForcesLtr(TextInputType.text), isFalse);
      expect(keyboardTypeForcesLtr(TextInputType.name), isFalse);
      expect(keyboardTypeForcesLtr(TextInputType.multiline), isFalse);
    });
  });

  test('normalizeToAsciiDigits converts Arabic and Persian numerals', () {
    expect(normalizeToAsciiDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(normalizeToAsciiDigits('۵۵۵'), '555');
    expect(normalizeToAsciiDigits('abc١٢3'), '123');
  });

  test('Arabic locale uses RTL for names and LTR for phone', () {
    expect(
      textDirectionForField(
        keyboardType: TextInputType.text,
        localeDirection: TextDirection.rtl,
      ),
      TextDirection.rtl,
    );
    expect(
      textDirectionForField(
        keyboardType: TextInputType.phone,
        localeDirection: TextDirection.rtl,
      ),
      TextDirection.ltr,
    );
  });

  testWidgets('showKeyboardFor focuses even when already focused', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(focusNode: node),
        ),
      ),
    );

    expect(node.hasFocus, isFalse);
    showKeyboardFor(node);
    await tester.pump();
    expect(node.hasFocus, isTrue);

    showKeyboardFor(node);
    await tester.pump();
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });
}
