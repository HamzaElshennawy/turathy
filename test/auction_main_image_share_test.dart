import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_main_image_widget.dart';

void main() {
  testWidgets('lot image does not cover the photo with share or favorite', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuctionMainImageWidget(
            images: const ['https://example.com/lot.jpg'],
            pageController: controller,
            onPageChanged: (_) {},
            statusLabel: 'لم يُبع',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.ios_share_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.text('لم يُبع'), findsOneWidget);
  });
}
