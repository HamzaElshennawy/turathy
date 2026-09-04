import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/live_bid_sync.dart';
import 'package:turathy/src/core/helper/socket/socket_models.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

void main() {
  group('BidPlacedEvent.fromJson', () {
    test('survives a null newBid (self-max rebid path)', () {
      final event = BidPlacedEvent.fromJson({
        'newBid': null,
        'currentPrice': 40,
        'productId': 13,
        'auctionBids': [],
      });
      expect(event.newBid, isNull);
      expect(event.currentPrice, 40);
      expect(event.eventProductId, 13);
    });

    test('parses currentPrice from a string without throwing', () {
      final event = BidPlacedEvent.fromJson({
        'newBid': null,
        'currentPrice': '55',
        'productId': 13,
      });
      expect(event.currentPrice, 55);
    });

    test('reads camelCase productId on nested bid', () {
      final event = BidPlacedEvent.fromJson({
        'newBid': {
          'id': 9,
          'userId': 4,
          'productId': 13,
          'bid': 20,
        },
        'currentPrice': 20,
      });
      expect(event.newBid?.userId, 4);
      expect(event.newBid?.productId, 13);
      expect(event.newBid?.bid, 20);
      expect(event.eventProductId, 13);
    });
  });

  group('live bid hold', () {
    test('held socket price wins over a stale REST actualPrice', () {
      final auction = AuctionModel(isLiveAuction: true, actualPrice: 10);
      applyHeldLiveFields(auction, heldPrice: 20);
      expect(auction.liveCurrentPrice, 20);
      expect(auction.actualPrice, 10);
    });

    test('held price after nextItem cannot exceed the new lot opening', () {
      final auction = AuctionModel(
        isLiveAuction: true,
        actualPrice: 10,
        bidPrice: 10,
      );
      applyHeldLiveFields(auction, heldPrice: 240);
      expect(auction.liveCurrentPrice, 240);
      expect(auction.actualPrice, 10);

      const opening = 10;
      final held = heldPriceForNextLot(opening);
      expect(held, opening);
      expect(held, isNot(240));

      auction.bidPrice = opening;
      applyHeldLiveFields(auction, heldPrice: held);

      expect(auction.liveCurrentPrice, opening);
      expect(auction.actualPrice, 10);
      expect(
        auction.liveCurrentPrice,
        lessThanOrEqualTo(auction.bidPrice ?? opening),
      );
    });

    test('stale snapshot from previous lot is ignored', () {
      expect(
        shouldIgnoreLiveBid(eventProductId: 3669, currentProductId: 3670),
        isTrue,
      );
    });

    test('ignores bids for a different live lot', () {
      expect(
        shouldIgnoreLiveBid(eventProductId: 2, currentProductId: 1),
        isTrue,
      );
      expect(
        shouldIgnoreLiveBid(eventProductId: 1, currentProductId: 1),
        isFalse,
      );
      expect(
        shouldIgnoreLiveBid(eventProductId: null, currentProductId: 1),
        isFalse,
      );
    });

    test('parseBidAcceptedPrice prefers visibleBid', () {
      expect(
        parseBidAcceptedPrice({
          'visibleBid': 30,
          'currentPrice': 20,
        }),
        30,
      );
    });

    test('resolvedCurrentPrice uses only the current lot hammer', () {
      final event = AuctionStateUpdateEvent(
        auctionId: 120,
        currentProductId: 3670,
        products: [
          StateUpdateProduct(
            id: 3669,
            topBids: [AuctionBid(bid: 240)],
          ),
          StateUpdateProduct(
            id: 3670,
            topBids: [AuctionBid(bid: 20)],
          ),
        ],
      );
      expect(event.resolvedCurrentPrice, 20);
    });
  });
}
