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

    test('an equal visible price of 50 is not a win when someone else leads', () {
      final decision = decideBidAccept(
        {
          'outbid': true,
          'submittedAmount': 50,
          'visibleBid': 50,
          'currentPrice': 50,
          'newBid': {'user_id': 80, 'bid': 50},
        },
        sessionUserId: 7,
      );
      expect(decision.visibleBid, 50);
      expect(decision.leaderUserId, 80);
      expect(
        sessionUserLeadsLot(
          sessionUserId: 7,
          leaderUserId: decision.leaderUserId,
          ackOutbid: decision.outbid,
          amountSaysLeader: true,
        ),
        isFalse,
      );
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

  test('a newer newBid replaces the leader and a late ack does not', () {
    final won = applyLiveLotPaint(
      current: null,
      incoming: const LiveLotPaintInput(
        fromAccepted: true,
        bidId: 10,
        leaderUserId: 7,
        price: 40,
        confrontation: 1,
        submittedAmount: 40,
        sessionUserId: 7,
      ),
    );
    expect(won.effect, LiveLotPaintEffect.painted);
    expect(won.paint.leaderUserId, 7);
    expect(won.paint.ownMax, 40);

    final overtaken = applyLiveLotPaint(
      current: won.paint,
      incoming: const LiveLotPaintInput(
        fromAccepted: false,
        bidId: 11,
        leaderUserId: 80,
        price: 50,
        confrontation: 2,
        sessionUserId: 7,
        participantIds: [7, 80],
      ),
    );
    expect(overtaken.paint.price, 50);
    expect(overtaken.paint.leaderUserId, 80);
    expect(overtaken.paint.confrontation, 2);
    expect(overtaken.paint.ownMax, isNull);
    expect(overtaken.paint.suppressOwnMax, isTrue);

    final late = applyLiveLotPaint(
      current: overtaken.paint,
      incoming: const LiveLotPaintInput(
        fromAccepted: true,
        bidId: 10,
        leaderUserId: 7,
        price: 40,
        confrontation: 1,
        submittedAmount: 40,
        sessionUserId: 7,
      ),
    );
    expect(late.effect, LiveLotPaintEffect.ignored);
    expect(late.paint.price, 50);
    expect(late.paint.leaderUserId, 80);
  });

  test('a tied ceiling hides when someone else leads', () {
    final held = applyLiveLotPaint(
      current: null,
      incoming: const LiveLotPaintInput(
        fromAccepted: true,
        productId: 6,
        bidId: 10,
        leaderUserId: 7,
        price: 40,
        confrontation: 1,
        submittedAmount: 40,
        sessionUserId: 7,
      ),
    );
    final tied = applyLiveLotPaint(
      current: held.paint,
      incoming: const LiveLotPaintInput(
        fromAccepted: false,
        productId: 6,
        bidId: 11,
        leaderUserId: 80,
        price: 40,
        confrontation: 2,
        sessionUserId: 7,
        participantIds: [7, 80],
      ),
    );
    expect(tied.paint.ownMax, isNull);
    expect(tied.paint.suppressOwnMax, isTrue);
    expect(tied.paint.leaderUserId, 80);
    expect(tied.paint.price, 40);
  });

  test('a later winning ceiling clears suppressOwnMax', () {
    const suppressed = LiveLotPaint(
      productId: 6,
      price: 40,
      confrontation: 2,
      leaderUserId: 80,
      bidId: 11,
      suppressOwnMax: true,
      userParticipated: true,
    );
    final recovered = applyLiveLotPaint(
      current: suppressed,
      incoming: const LiveLotPaintInput(
        fromAccepted: true,
        productId: 6,
        bidId: 12,
        leaderUserId: 7,
        price: 50,
        confrontation: 3,
        submittedAmount: 80,
        sessionUserId: 7,
      ),
    );
    expect(recovered.effect, LiveLotPaintEffect.painted);
    expect(recovered.paint.suppressOwnMax, isFalse);
    expect(recovered.paint.ownMax, 80);
    expect(recovered.paint.leaderUserId, 7);
  });

  test('an event for another lot is ignored and a reset lot accepts a lower id', () {
    final lotSix = applyLiveLotPaint(
      current: null,
      incoming: const LiveLotPaintInput(
        fromAccepted: false,
        productId: 6,
        bidId: 11,
        leaderUserId: 80,
        price: 40,
        confrontation: 2,
        sessionUserId: 7,
      ),
    );
    final otherLot = applyLiveLotPaint(
      current: lotSix.paint,
      incoming: const LiveLotPaintInput(
        fromAccepted: true,
        productId: 7,
        bidId: 12,
        leaderUserId: 7,
        price: 15,
        confrontation: 1,
        submittedAmount: 15,
        sessionUserId: 7,
      ),
    );
    expect(otherLot.effect, LiveLotPaintEffect.ignored);
    expect(otherLot.paint.productId, 6);
    expect(otherLot.paint.price, 40);

    final freshLot = applyLiveLotPaint(
      current: null,
      incoming: const LiveLotPaintInput(
        fromAccepted: true,
        productId: 7,
        bidId: 3,
        leaderUserId: 7,
        price: 15,
        confrontation: 1,
        submittedAmount: 20,
        sessionUserId: 7,
      ),
    );
    expect(freshLot.effect, LiveLotPaintEffect.painted);
    expect(freshLot.paint.productId, 7);
    expect(freshLot.paint.bidId, 3);
    expect(freshLot.paint.suppressOwnMax, isFalse);
  });

  test('a second swipe does not emit while the lot is pending', () {
    expect(shouldEmitLiveBid(pendingForProduct: true), isFalse);
    expect(shouldEmitLiveBid(pendingForProduct: false), isTrue);
  });
}
