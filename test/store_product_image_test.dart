import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/common_widgets/store_product_image.dart';

void main() {
  testWidgets('store product image uses contain so the photo is not cropped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 80,
            child: StoreProductImage(
              imageUrl: 'https://example.com/coin.jpg',
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.fit, StoreProductImage.imageFit);
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('empty store image shows a placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 80,
            height: 80,
            child: StoreProductImage(imageUrl: ''),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
}
