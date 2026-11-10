import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/all_auctions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('auctions tab has no dead filter floating button', () {
    final source = File('lib/src/features/main_screen.dart').readAsStringSync();
    expect(source.contains('auctions_filter_fab'), isFalse);
    expect(source.contains('floatingActionButton:'), isFalse);
  });

  testWidgets('tap or drag outside the auctions search unfocuses it', (
    tester,
  ) async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(_auctionsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.text('لا يوجد مزادات حاليا'));
    await tester.pump();

    expect(editable.focusNode.hasFocus, isFalse);
    expect(find.byIcon(Icons.tune), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.drag(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.vertical,
      ),
      const Offset(0, -80),
    );
    await tester.pump();

    expect(editable.focusNode.hasFocus, isFalse);
  });
}

Widget _auctionsApp() {
  return EasyLocalization(
    supportedLocales: const [Locale('ar')],
    path: 'assets/lang',
    fallbackLocale: const Locale('ar'),
    startLocale: const Locale('ar'),
    child: ProviderScope(
      overrides: [
        filteredAuctionsProvider.overrideWith((ref) async => []),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const Scaffold(body: AllAuctionsScreen()),
          );
        },
      ),
    ),
  );
}
