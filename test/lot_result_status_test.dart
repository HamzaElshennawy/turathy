import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/lot_result_status.dart';
import 'package:turathy/src/core/helper/socket/socket_models.dart';

void main() {
  group('lotWasSold', () {
    test('event isSold false wins even when a winner payload exists', () {
      expect(
        lotWasSold(eventIsSold: false, hasWinner: true, productIsSold: true),
        isFalse,
      );
    });

    test('product isSold true is used when event flag is absent', () {
      expect(lotWasSold(productIsSold: true), isTrue);
      expect(lotWasSold(productIsSold: false), isFalse);
    });

    test('winner fallback only when both flags are null', () {
      expect(lotWasSold(hasWinner: true), isTrue);
      expect(lotWasSold(hasWinner: false), isFalse);
    });
  });

  group('resolveLotResult', () {
    test('live when not ended', () {
      expect(
        resolveLotResult(
          isEnded: false,
          isLive: true,
          isSold: false,
          userParticipated: true,
          currentUserId: 1,
          winnerUserId: 1,
        ),
        LotResultKind.live,
      );
    });

    test('upcoming (none) when not ended and not live', () {
      expect(
        resolveLotResult(
          isEnded: false,
          isLive: false,
          isSold: false,
          userParticipated: false,
        ),
        LotResultKind.none,
      );
    });

    test('unsold when ended and not sold even if user had the high bid', () {
      expect(
        resolveLotResult(
          isEnded: true,
          isLive: false,
          isSold: false,
          currentUserId: 10,
          winnerUserId: 10,
          userParticipated: true,
        ),
        LotResultKind.unsold,
      );
    });

    test('youWon only when sold and current user is winner', () {
      expect(
        resolveLotResult(
          isEnded: true,
          isLive: false,
          isSold: true,
          currentUserId: 10,
          winnerUserId: 10,
          userParticipated: true,
        ),
        LotResultKind.youWon,
      );
    });

    test('youLost when sold, user bid, but is not winner', () {
      expect(
        resolveLotResult(
          isEnded: true,
          isLive: false,
          isSold: true,
          currentUserId: 10,
          winnerUserId: 99,
          userParticipated: true,
        ),
        LotResultKind.youLost,
      );
    });

    test('past sold lot is not drawn unsold', () {
      final kind = visibleLotResult(
        resolveLotResult(
          isEnded: true,
          isLive: false,
          isSold: true,
          userParticipated: false,
        ),
        thisLotHasEnded: true,
      );
      expect(kind, isNot(LotResultKind.unsold));
      expect(kind, LotResultKind.sold);
    });

    test('ended lot without a sale flag stays unsold', () {
      final kind = visibleLotResult(
        resolveLotResult(
          isEnded: true,
          isLive: false,
          isSold: false,
          userParticipated: true,
        ),
        thisLotHasEnded: true,
      );
      expect(kind, LotResultKind.unsold);
    });

    test('sold when sold and user did not bid', () {
      expect(
        resolveLotResult(
          isEnded: true,
          isLive: false,
          isSold: true,
          currentUserId: 10,
          winnerUserId: 99,
          userParticipated: false,
        ),
        LotResultKind.sold,
      );
    });
  });

  group('endedLotApply', () {
    test('alreadyOnNext still records the sale and skips side effects', () {
      final apply = endedLotApply(
        endedProductId: 11,
        lastEndedProductId: null,
        nextItemId: 12,
        currentProductId: 12,
        eventIsSold: true,
        hasWinner: true,
      );
      expect(apply.sold, isTrue);
      expect(apply.runSideEffects, isFalse);
      expect(
        visibleLotResult(
          resolveLotResult(
            isEnded: true,
            isLive: false,
            isSold: apply.sold == true,
            userParticipated: false,
          ),
          thisLotHasEnded: true,
        ),
        isNot(LotResultKind.unsold),
      );
    });

    test('a repeated endedProductId still records the sale', () {
      final apply = endedLotApply(
        endedProductId: 11,
        lastEndedProductId: 11,
        nextItemId: 12,
        currentProductId: 11,
        eventIsSold: true,
        hasWinner: false,
      );
      expect(apply.sold, isTrue);
      expect(apply.runSideEffects, isFalse);
    });

    test('the first end event records the sale and runs side effects', () {
      final apply = endedLotApply(
        endedProductId: 11,
        lastEndedProductId: null,
        nextItemId: 12,
        currentProductId: 11,
        eventIsSold: true,
        hasWinner: true,
      );
      expect(apply.sold, isTrue);
      expect(apply.runSideEffects, isTrue);
    });

    test('a missing isSold flag does not become unsold or clear a sale', () {
      final apply = endedLotApply(
        endedProductId: 11,
        lastEndedProductId: null,
        nextItemId: 12,
        currentProductId: 12,
        eventIsSold: null,
        hasWinner: false,
      );
      expect(apply.sold, isNull);
      expect(apply.runSideEffects, isFalse);
      expect(
        explicitLotSale(eventIsSold: apply.sold, productIsSold: false),
        isNull,
      );
      expect(
        explicitLotSale(eventIsSold: true, productIsSold: false),
        isTrue,
      );
      expect(
        explicitLotSale(productIsSold: true, productExpired: false),
        isTrue,
      );
      expect(
        explicitLotSale(productExpired: true, productIsSold: false),
        isFalse,
      );
    });
  });

  group('sold badge waits for an explicit close', () {
    test('moving the live pointer with an empty sale flag is not unsold', () {
      final stampId = endedLotIdToStamp(
        eventEndedProductId: null,
        currentProductId: 12,
        nextItemId: 12,
        productIdsInOrder: [11, 12],
      );
      expect(stampId, 11);
      expect(explicitLotSale(productIsSold: null, productExpired: null), isNull);
      expect(
        settledLotBadge(
          isSold: false,
          explicitlyUnsold: false,
          userParticipated: false,
        ),
        LotResultKind.none,
      );
    });

    test('an ended event with isSold true is sold', () {
      expect(
        settledLotBadge(
          isSold: badgeLotWasSold(eventIsSold: true, productIsSold: false),
          explicitlyUnsold: lotExplicitlyUnsold(eventIsSold: true),
          userParticipated: false,
        ),
        LotResultKind.sold,
      );
    });

    test('an ended event with isSold false is unsold', () {
      expect(
        settledLotBadge(
          isSold: badgeLotWasSold(eventIsSold: false),
          explicitlyUnsold: lotExplicitlyUnsold(eventIsSold: false),
          userParticipated: true,
        ),
        LotResultKind.unsold,
      );
    });

    test('a sold product beats a stale session false', () {
      expect(
        explicitLotSale(eventIsSold: false, productIsSold: true),
        isTrue,
      );
      expect(
        badgeLotWasSold(eventIsSold: false, productIsSold: true),
        isTrue,
      );
    });
  });

  group('lotResultStringKey', () {
    test('maps kinds to AppStrings keys', () {
      expect(lotResultStringKey(LotResultKind.live), AppStrings.live);
      expect(lotResultStringKey(LotResultKind.youWon), AppStrings.youWon);
      expect(lotResultStringKey(LotResultKind.youLost), AppStrings.youLost);
      expect(lotResultStringKey(LotResultKind.sold), AppStrings.sold);
      expect(lotResultStringKey(LotResultKind.unsold), AppStrings.unsold);
    });
  });

  group('AuctionItemEndedEvent extras', () {
    test('parses isSold, endedProductId, and reason', () {
      final event = AuctionItemEndedEvent.fromJson({
        'auction': {'id': 97, 'title': 'Auction 97', 'type': 'Live'},
        'isSold': false,
        'endedProductId': 3266,
        'reason': 'reserve_not_met',
      });

      expect(event.isSold, isFalse);
      expect(event.endedProductId, 3266);
      expect(event.reason, 'reserve_not_met');
      expect(event.winner, isNull);
    });

    test('parses is_sold snake_case and ended_product_id', () {
      final event = AuctionItemEndedEvent.fromJson({
        'auction': {'id': 1, 'type': 'Live'},
        'is_sold': true,
        'ended_product_id': '12',
        'winner': {'id': 4, 'name': 'Ali', 'number': '5'},
      });

      expect(event.isSold, isTrue);
      expect(event.endedProductId, 12);
      expect(event.winner?.id, 4);
    });
  });

  group('live lot pointer helpers', () {
    test('isCurrentLiveLot matches product id', () {
      expect(
        isCurrentLiveLot(
          productId: 37,
          productName: 'A',
          currentProductId: 37,
          currentProductName: 'Other',
        ),
        isTrue,
      );
      expect(
        isCurrentLiveLot(
          productId: 36,
          productName: 'A',
          currentProductId: 37,
          currentProductName: 'A',
        ),
        isFalse,
      );
    });

    test('isCurrentLiveLot is true when server has no pointer', () {
      expect(
        isCurrentLiveLot(
          productId: 1,
          productName: 'Lot',
          currentProductId: null,
          currentProductName: null,
        ),
        isTrue,
      );
    });

    test('isUpcomingLiveLot is true only after the current index', () {
      expect(
        isUpcomingLiveLot(
          productIdsInOrder: const [10, 11, 12],
          selectedProductId: 12,
          currentProductId: 11,
        ),
        isTrue,
      );
      expect(
        isUpcomingLiveLot(
          productIdsInOrder: const [10, 11, 12],
          selectedProductId: 10,
          currentProductId: 11,
        ),
        isFalse,
      );
    });

    test('isCurrentLiveLotClosedByServer ignores a local clock', () {
      expect(
        isCurrentLiveLotClosedByServer(isAuctionEnded: false),
        isFalse,
      );
      expect(
        isCurrentLiveLotClosedByServer(
          isAuctionEnded: false,
          productExpired: true,
        ),
        isTrue,
      );
    });
  });

  group('auctionIsFullyEnded', () {
    test('false while live even if a lot timer is at zero', () {
      expect(
        auctionIsFullyEnded(isAuctionEnded: false),
        isFalse,
      );
    });

    test('true from explicit ended, expired, or canceled', () {
      expect(
        auctionIsFullyEnded(isAuctionEnded: true),
        isTrue,
      );
      expect(
        auctionIsFullyEnded(isAuctionEnded: false, isExpired: true),
        isTrue,
      );
      expect(
        auctionIsFullyEnded(isAuctionEnded: false, isCanceled: true),
        isTrue,
      );
    });
  });

  group('visibleLotResult', () {
    test('hides unsold while this lot is still open on the server', () {
      expect(
        visibleLotResult(
          LotResultKind.unsold,
          thisLotHasEnded: false,
        ),
        LotResultKind.none,
      );
    });

    test('shows unsold after this lot ends during a live auction', () {
      expect(
        visibleLotResult(
          LotResultKind.unsold,
          thisLotHasEnded: true,
        ),
        LotResultKind.unsold,
      );
    });

    test('keeps sold and won during a live auction', () {
      expect(
        visibleLotResult(
          LotResultKind.youWon,
          thisLotHasEnded: false,
        ),
        LotResultKind.youWon,
      );
      expect(
        visibleLotResult(
          LotResultKind.sold,
          thisLotHasEnded: false,
        ),
        LotResultKind.sold,
      );
      expect(
        visibleLotResult(
          LotResultKind.youLost,
          thisLotHasEnded: false,
        ),
        LotResultKind.youLost,
      );
    });
  });

  group('overlayLotResult', () {
    test('hides sold overlay on an open live lot', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.sold,
          resultProductId: 10,
          selectedProductId: 11,
          currentLiveProductId: 11,
          selectedLotClosedByServer: false,
        ),
        LotResultKind.none,
      );
      expect(
        overlayLotResult(
          kind: LotResultKind.sold,
          resultProductId: 11,
          selectedProductId: 11,
          currentLiveProductId: 11,
          selectedLotClosedByServer: false,
        ),
        LotResultKind.none,
      );
    });

    test('hides youWon overlay on an open live lot', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.youWon,
          resultProductId: 10,
          selectedProductId: 11,
          currentLiveProductId: 11,
          selectedLotClosedByServer: false,
        ),
        LotResultKind.none,
      );
    });

    test('hides previous lot unsold on the next live item', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.unsold,
          resultProductId: 10,
          selectedProductId: 11,
          currentLiveProductId: 11,
          selectedLotClosedByServer: false,
        ),
        LotResultKind.none,
      );
    });

    test('hides unsold even if resultProductId matches the open live lot', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.unsold,
          resultProductId: 10,
          selectedProductId: 10,
          currentLiveProductId: 10,
          selectedLotClosedByServer: false,
        ),
        LotResultKind.none,
      );
    });

    test('hides unsold when selected id is missing on an open live auction', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.unsold,
          resultProductId: 10,
          selectedProductId: null,
          currentLiveProductId: 11,
          selectedLotClosedByServer: false,
        ),
        LotResultKind.none,
      );
    });

    test('shows unsold on the ended lot after the server closed it', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.unsold,
          resultProductId: 10,
          selectedProductId: 10,
          currentLiveProductId: null,
          selectedLotClosedByServer: true,
        ),
        LotResultKind.unsold,
      );
    });

    test('shows unsold when browsing that past lot during a live auction', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.unsold,
          resultProductId: 10,
          selectedProductId: 10,
          currentLiveProductId: 11,
          selectedLotClosedByServer: true,
        ),
        LotResultKind.unsold,
      );
    });

    test('hides sold on the open live item', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.sold,
          resultProductId: 10,
          selectedProductId: 11,
          currentLiveProductId: 11,
          selectedLotClosedByServer: false,
        ),
        LotResultKind.none,
      );
    });

    test('hides youWon on the open live item', () {
      expect(
        overlayLotResult(
          kind: LotResultKind.youWon,
          resultProductId: 10,
          selectedProductId: 10,
          currentLiveProductId: 10,
          selectedLotClosedByServer: false,
        ),
        LotResultKind.none,
      );
    });
  });
}
