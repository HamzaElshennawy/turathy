import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({
  required Locale locale,
  required Widget home,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      CountryLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

void main() {
  testWidgets('country names are Arabic when app locale is ar', (tester) async {
    String? name;
    await tester.pumpWidget(
      _app(
        locale: const Locale('ar'),
        home: Builder(
          builder: (context) {
            name = CountryCode.fromCountryCode('SA').localize(context).name;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(name, 'السعودية');
  });

  testWidgets('country names are English when app locale is en', (tester) async {
    String? name;
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            name = CountryCode.fromCountryCode('SA').localize(context).name;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(name, 'Saudi Arabia');
  });
}
