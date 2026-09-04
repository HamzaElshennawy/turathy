import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/common_widgets/cached_lot_image.dart';

void main() {
  testWidgets('empty url shows grey placeholder without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: CachedLotImage(imageUrl: ''),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image), findsOneWidget);
  });

  testWidgets('null url shows grey placeholder without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: CachedLotImage(imageUrl: null),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image), findsOneWidget);
  });
}
