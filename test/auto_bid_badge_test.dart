import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/domain/max_bid_model.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';

void main() {
  const userId = 7;
  const productId = 42;

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

  test('inactive cap stays hidden even while the price is below it', () {
    expect(
      shown(visiblePrice: 100, bids: [cap(isActive: false)]),
      isFalse,
    );
  });
}
