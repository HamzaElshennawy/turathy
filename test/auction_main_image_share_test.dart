import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_main_image_widget.dart';

void main() {
  testWidgets('lot image shows share overlay when onShare is provided', (
    tester,
  ) async {
    var shared = 0;
    final controller = PageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuctionMainImageWidget(
            images: const [
              'https://example.com/lot.jpg',
            ],
            pageController: controller,
            onPageChanged: (_) {},
            onShare: () => shared++,
          ),
        ),
      ),
    );
    await tester.pump();

    final share = find.byKey(const Key('lot_share_button'));
    expect(share, findsOneWidget);

    await tester.tap(share);
    await tester.pump();
    expect(shared, 1);

    controller.dispose();
  });

  testWidgets('lot image hides share overlay when onShare is null', (
    tester,
  ) async {
    final controller = PageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuctionMainImageWidget(
            images: const ['https://example.com/lot.jpg'],
            pageController: controller,
            onPageChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('lot_share_button')), findsNothing);
    controller.dispose();
  });
}
