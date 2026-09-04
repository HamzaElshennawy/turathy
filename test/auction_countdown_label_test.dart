import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_countdown_label.dart';

void main() {
  testWidgets('AuctionCountdownLabel shows formatted remaining time', (
    tester,
  ) async {
    final target = DateTime.now().add(
      const Duration(hours: 1, minutes: 2, seconds: 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuctionCountdownLabel(target: target),
        ),
      ),
    );

    expect(find.byType(Text), findsOneWidget);
    expect(find.textContaining(':'), findsOneWidget);
  });

  test('formatDuration matches auction screen style', () {
    expect(
      AuctionCountdownLabel.formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '01:02:03',
    );
    expect(
      AuctionCountdownLabel.formatDuration(const Duration(minutes: 5, seconds: 9)),
      '05:09',
    );
    expect(
      AuctionCountdownLabel.formatDuration(const Duration(seconds: 7)),
      '7 sec',
    );
  });
}
