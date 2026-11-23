import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/socket/socket_models.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/domain/max_bid_model.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';

void main() {
  const userId = 7;
  const productId = 42;

  AuctionBid capBid({bool? isActive}) {
    return AuctionBid(bid: 10, isActive: isActive, userId: userId);
  }

  MaxBidModel cap({
    int? owner = userId,
    int? lot = productId,
    num? maxAmount = 200,
    bool? isActive = true,
  }) {
    return MaxBidModel(
      userId: owner,
      productId: lot,
      maxAmount: maxAmount,
      isActive: isActive,
    );
  }

  bool shown({
    required num visiblePrice,
    required List<MaxBidModel> bids,
    bool sellerBlocked = false,
    int? sessionUserId = userId,
    int? openProductId = productId,
  }) {
    return shouldShowAutoBidBadge(
      sellerBlocked: sellerBlocked,
      sessionUserId: sessionUserId,
      productId: openProductId,
      visiblePrice: visiblePrice,
      bids: bids,
    );
  }

  test('owner of cap 200 sees the draft while the visible price is 200', () {
    expect(shown(visiblePrice: 200, bids: [cap()]), isTrue);
    expect(
      autoBidBadgeSentence(200),
      'لديك مزايدة تلقائية بحد أقصى 200 ر.س',
    );
  });

  test('badge hides when the visible price is 201', () {
    expect(shown(visiblePrice: 201, bids: [cap()]), isFalse);
  });

  test('another user cap on the same lot is not shown', () {
    expect(
      shown(visiblePrice: 100, bids: [cap(owner: 99, maxAmount: 200)]),
      isFalse,
    );
    expect(
      activeOwnMaxAmount(
        sessionUserId: userId,
        productId: productId,
        bids: [cap(owner: 99, maxAmount: 900), cap(maxAmount: 200)],
      ),
      200,
    );
  });

  test('a lot with no matching cap shows no sentence', () {
    expect(shown(visiblePrice: 100, bids: const []), isFalse);
    expect(
      shown(visiblePrice: 100, bids: [cap(lot: 8)]),
      isFalse,
    );
    expect(
      shown(visiblePrice: 100, bids: [cap(isActive: null)]),
      isFalse,
    );
    expect(
      shown(visiblePrice: 100, bids: [cap(owner: null)]),
      isFalse,
    );
    expect(
      shown(visiblePrice: 100, bids: [cap(lot: null)]),
      isFalse,
    );
    expect(shown(visiblePrice: 100, bids: [cap()], openProductId: null), isFalse);
  });

  test('seller block hides the badge', () {
    expect(
      shown(visiblePrice: 100, bids: [cap()], sellerBlocked: true),
      isFalse,
    );
  });

  test('a saved ceiling of 40 shows while the visible price is still 20', () {
    final ack = ownMaxAfterAccept(outbid: false, submittedAmount: 40);
    final price = visiblePriceAfterAccept(
      visiblePrice: 20,
      acceptedCurrentPrice: 40,
    );
    expect(price, 40);
    expect(shouldClearAcceptedBidState(productChanged: false), isFalse);
    expect(
      visibleOwnMaxAmount(
        acceptedOwnMax: ack.amount,
        suppressServerMax: ack.suppressServerMax,
        sessionUserId: userId,
        productId: productId,
        bids: const [],
      ),
      40,
    );
    expect(
      autoBidBadgeSentence(ack.amount!),
      'لديك مزايدة تلقائية بحد أقصى 40 ر.س',
    );
  });

  test('a timer change does not clear the accepted ceiling', () {
    expect(shouldClearAcceptedBidState(productChanged: false), isFalse);
    expect(shouldClearAcceptedBidState(productChanged: true), isTrue);
  });

  test('a missing isActive flag still counts as a public confrontation', () {
    expect(
      visibleConfrontationCount([
        capBid(isActive: null),
        capBid(isActive: true),
        capBid(isActive: false),
      ]),
      2,
    );
  });

  test('a saved ceiling of 520 shows while the visible price stays 20', () {
    final ack = ownMaxAfterAccept(outbid: false, submittedAmount: 520);
    expect(ack.suppressServerMax, isFalse);
    final maxAmount = visibleOwnMaxAmount(
      acceptedOwnMax: ack.amount,
      suppressServerMax: ack.suppressServerMax,
      sessionUserId: userId,
      productId: productId,
      bids: const [],
    );
    expect(maxAmount, 520);
    expect(
      shouldShowAutoBidBadge(
        sellerBlocked: false,
        sessionUserId: userId,
        productId: productId,
        visiblePrice: 20,
        bids: [cap(maxAmount: maxAmount)],
      ),
      isTrue,
    );
    expect(
      autoBidBadgeSentence(maxAmount!),
      'لديك مزايدة تلقائية بحد أقصى 520 ر.س',
    );
  });

  test('an outbid ack hides a stale server ceiling without a newBid', () {
    final ack = ownMaxAfterAccept(outbid: true, submittedAmount: 520);
    expect(ack.amount, isNull);
    expect(ack.suppressServerMax, isTrue);
    expect(
      visibleOwnMaxAmount(
        acceptedOwnMax: ack.amount,
        suppressServerMax: ack.suppressServerMax,
        sessionUserId: userId,
        productId: productId,
        bids: [cap(maxAmount: 520)],
      ),
      isNull,
    );
  });

  test('bidAccepted carries the ceiling when the public price does not move', () {
    final event = BidAcceptedEvent.fromJson({
      'productId': 42,
      'submittedAmount': 520,
      'currentPrice': 20,
      'outbid': false,
    });
    final ack = ownMaxAfterAccept(
      outbid: event.outbid,
      submittedAmount: event.submittedAmount,
    );
    expect(event.currentPrice, 20);
    expect(ack.amount, 520);
    expect(ack.suppressServerMax, isFalse);
  });

  test('a rejected bid replaces a stale visible price of 10', () {
    expect(
      visiblePriceAfterRejection(visiblePrice: 10, rejectedCurrentPrice: 160),
      160,
    );
    expect(
      visiblePriceAfterRejection(visiblePrice: 10, rejectedCurrentPrice: null),
      10,
    );
    final rejected = BidRejectedEvent.fromJson({
      'message': 'Bid must be at least 170',
      'currentPrice': 160,
      'productId': 42.0,
    });
    expect(rejected.currentPrice, 160);
    expect(rejected.productId, 42);
  });

  test('inactive cap stays hidden even while the price is below it', () {
    expect(
      shown(visiblePrice: 100, bids: [cap(isActive: false)]),
      isFalse,
    );
  });
}
