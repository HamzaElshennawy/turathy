import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/common_widgets/white_rounded_text_form_field.dart';

void main() {
  testWidgets('Arabic Directionality uses RTL on text and LTR on phone', (
    tester,
  ) async {
    final textController = TextEditingController();
    final phoneController = TextEditingController();
    addTearDown(textController.dispose);
    addTearDown(phoneController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ListView(
            children: [
              WhiteRoundedTextFormField(
                key: const Key('name_field'),
                controller: textController,
                validator: (_) => null,
                keyboardType: TextInputType.text,
                hintText: 'name',
              ),
              WhiteRoundedTextFormField(
                key: const Key('phone_field'),
                controller: phoneController,
                validator: (_) => null,
                keyboardType: TextInputType.phone,
                hintText: 'phone',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('name_field')),
        matching: find.byType(TextField),
      ),
    );
    final phoneField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('phone_field')),
        matching: find.byType(TextField),
      ),
    );

    expect(nameField.textDirection, TextDirection.rtl);
    expect(phoneField.textDirection, TextDirection.ltr);
    expect(nameField.readOnly, isFalse);
    expect(nameField.keyboardType, TextInputType.text);
  });
}
