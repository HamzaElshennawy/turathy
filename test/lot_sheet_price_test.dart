import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/auction_price_helpers.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

void main() {
  test('lot sheet uses the list price when it is above the opening bid', () {
    expect(
      highestVisibleBid(
        openingPrice: 10,
        knownHighest: 540,
        amounts: const [520],
      ),
      540,
    );
  });

  test('lot sheet keeps bids stored on the lot when the auction list omits them', () {
    final lotBid = AuctionBid(id: 50, productId: 1, bid: 520, isActive: true);
    final otherLot = AuctionBid(id: 9, productId: 2, bid: 900, isActive: true);

    final bids = bidsForSelectedLot(
      productBids: [lotBid],
      auctionBids: [otherLot],
      productId: 1,
    );

    expect(bids.map((bid) => bid.bid).toList(), [520]);
  });
}
