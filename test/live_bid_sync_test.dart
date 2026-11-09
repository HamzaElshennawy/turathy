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

    test('explicit outbid flag means the bidder is not the leader', () {
      final decision = decideBidAccept(
        {
          'outbid': true,
          'submittedAmount': 340,
          'visibleBid': 350,
          'newBid': {'user_id': 326, 'bid': 350},
        },
        sessionUserId: 550,
      );
      expect(decision.outbid, isTrue);
      expect(decision.visibleBid, 350);
      expect(decision.submittedAmount, 340);
      expect(decision.leaderUserId, 326);
    });

    test('a different leader without the flag is not inferred as outbid', () {
      final decision = decideBidAccept(
        {
          'submittedAmount': 340,
          'currentPrice': 350,
          'newBid': {'userId': 326, 'bid': 350},
        },
        sessionUserId: 550,
      );
      expect(decision.outbid, isFalse);
      expect(decision.leaderUserId, 326);
    });

    test('the same user leading is not an outbid', () {
      final decision = decideBidAccept(
        {
          'outbid': false,
          'submittedAmount': 350,
          'visibleBid': 350,
          'newBid': {'user_id': 550, 'bid': 350},
        },
        sessionUserId: 550,
      );
      expect(decision.outbid, isFalse);
    });
  });

  test('a second swipe does not emit while the lot is pending', () {
    expect(shouldEmitLiveBid(pendingForProduct: true), isFalse);
    expect(shouldEmitLiveBid(pendingForProduct: false), isTrue);
  });
}
