import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/bid_steps.dart';
import 'package:turathy/src/features/auctions/data/auction_access_service.dart';

void main() {
  group('Bidding Controls & Price Synchronization', () {
    test('maxBidFloor prefers currentPrice over stale highestActiveBid', () {
      const num? highestBid = 200;
      const num currentPrice = 740;
      const num openingPrice = 100;

      expect(highestBid ?? currentPrice, 200);

      final floor = maxBidFloor(
        highestActiveBid: highestBid,
        currentPrice: currentPrice,
        openingPrice: openingPrice,
      );
      expect(floor, 740);

      final steps = buildBidSteps(floor, 50);
      expect(steps.first, greaterThan(currentPrice));
      expect(steps.first, 760);
      expect(steps.contains(720), isFalse);
    });

    test('one-step swipe uses floor + increment, not stale highest bid', () {
      expect(
        nextOneStepBid(
          highestActiveBid: 200,
          currentPrice: 740,
          openingPrice: 100,
        ),
        760,
      );
    });

    test('normalizeAuctionAccessStatus maps backend statuses to UI contract', () {
      expect(normalizeAuctionAccessStatus('APPROVED'), 'GRANTED');
      expect(normalizeAuctionAccessStatus('approved'), 'GRANTED');
      expect(normalizeAuctionAccessStatus('AUTO_APPROVED'), 'GRANTED');
      expect(
        normalizeAuctionAccessStatus('PROFILE_INCOMPLETE'),
        'PROFILE_INCOMPLETE',
      );
      expect(normalizeAuctionAccessStatus('BLOCKED'), 'DENIED');
      expect(isAuctionAccessGranted('APPROVED'), isTrue);
      expect(isAuctionAccessGranted('GRANTED'), isTrue);
      expect(isAuctionAccessGranted('PENDING'), isFalse);
      expect(isAuctionAccessDenied('BLOCKED'), isTrue);
      expect(isAuctionProfileIncomplete('PROFILE_INCOMPLETE'), isTrue);
      expect(isAuctionAccessPending('PENDING'), isTrue);
      expect(isAuctionAccessPending('PROFILE_INCOMPLETE'), isFalse);
    });

    test('AppStrings.needAdminApprovalToBid key exists', () {
      expect(AppStrings.needAdminApprovalToBid, 'needAdminApprovalToBid');
    });
  });
}
