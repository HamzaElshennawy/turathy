import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/live_bid_sync.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

void main() {
  group('live bid ACK matching', () {
    const pending = PendingClientBid(
      clientBidId: 'client-1',
      auctionId: 12,
      productId: 44,
      amount: 760,
    );

    test('matches when auction, product, and clientBidId align', () {
      expect(
        matchesPendingBidAck(
          data: {
            'auctionId': 12,
            'productId': 44,
            'clientBidId': 'client-1',
            'submittedAmount': 760,
            'visibleBid': 760,
          },
          pending: pending,
        ),
        isTrue,
      );
    });

    test('fails closed when auction or product is missing', () {
      expect(
        matchesPendingBidAck(
          data: {
            'clientBidId': 'client-1',
            'submittedAmount': 760,
            'visibleBid': 760,
          },
          pending: pending,
        ),
        isFalse,
      );
    });

    test('rejects a different lot or auction', () {
      expect(
        matchesPendingBidAck(
          data: {
            'auctionId': 12,
            'productId': 99,
            'clientBidId': 'client-1',
          },
          pending: pending,
        ),
        isFalse,
      );
    });

    test('applyHeldLiveFields writes liveCurrentPrice, not actualPrice', () {
      final auction = AuctionModel(id: 1, actualPrice: 900, isLiveAuction: true);
      applyHeldLiveFields(auction, heldPrice: 760);
      expect(auction.liveCurrentPrice, 760);
      expect(auction.actualPrice, 900);
    });
  });
}
