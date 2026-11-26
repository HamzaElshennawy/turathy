import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/domain/max_bid_model.dart';
import 'package:turathy/src/features/auctions/domain/winning_auction_model.dart';
import 'package:turathy/src/features/orders/presentation/order_details_screen.dart';
import 'package:turathy/src/features/orders/domain/order_flow_state.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';

import 'package:turathy/src/core/helper/live_bid_sync.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';
import 'package:turathy/src/core/time/server_clock.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/auction_price_helpers.dart';
import 'package:turathy/src/core/helper/bid_steps.dart';
import 'package:turathy/src/core/helper/lot_result_status.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/lot_result_banner.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/swipe_to_bid_bar.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_expiry_clock.dart';

/// Draft sentence until the client confirms the final wording.
String autoBidBadgeSentence(num maxAmount) =>
    'لديك مزايدة تلقائية بحد أقصى $maxAmount ر.س';

/// Active cap for this session user and this lot only.
/// A null [MaxBidModel.isActive], user, or product does not match.
num? activeOwnMaxAmount({
  required int? sessionUserId,
  required int? productId,
  required Iterable<MaxBidModel> bids,
}) {
  if (sessionUserId == null || productId == null) return null;
  for (final bid in bids) {
    if (bid.isActive != true) continue;
    if (bid.userId != sessionUserId) continue;
    if (bid.productId != productId) continue;
    final maxAmount = bid.maxAmount;
    if (maxAmount == null) continue;
    return maxAmount;
  }
  return null;
}

/// What to paint after `bidAccepted`. A higher ceiling does not need `newBid`.
/// An outbid ack hides the server list until this sheet is opened again.
class OwnMaxAck {
  const OwnMaxAck({required this.amount, required this.suppressServerMax});

  final num? amount;
  final bool suppressServerMax;
}

OwnMaxAck ownMaxAfterAccept({
  required bool outbid,
  required num? submittedAmount,
}) {
  if (outbid) {
    return const OwnMaxAck(amount: null, suppressServerMax: true);
  }
  final amount =
      submittedAmount != null && submittedAmount > 0 ? submittedAmount : null;
  return OwnMaxAck(amount: amount, suppressServerMax: false);
}

/// Local ceiling wins immediately. The server list is used only when no ack
/// is pending, and is ignored after an outbid until the sheet reopens.
num? visibleOwnMaxAmount({
  required num? acceptedOwnMax,
  required bool suppressServerMax,
  required int? sessionUserId,
  required int? productId,
  required Iterable<MaxBidModel> bids,
}) {
  if (acceptedOwnMax != null) return acceptedOwnMax;
  if (suppressServerMax) return null;
  return activeOwnMaxAmount(
    sessionUserId: sessionUserId,
    productId: productId,
    bids: bids,
  );
}

/// A timer reset must not wipe a ceiling that was just saved.
bool shouldClearAcceptedBidState({required bool productChanged}) =>
    productChanged;

/// The accepted public price replaces a stale on-screen price.
num visiblePriceAfterAccept({
  required num visiblePrice,
  required num? acceptedCurrentPrice,
}) {
  if (acceptedCurrentPrice != null && acceptedCurrentPrice > visiblePrice) {
    return acceptedCurrentPrice;
  }
  return visiblePrice;
}

/// Socket rows omit `is_active`. Those are public bids. Only an explicit
/// false is a hidden proxy row and stays out of the confrontation count.
int visibleConfrontationCount(Iterable<AuctionBid> bids) =>
    bids.where((bid) => bid.isActive != false).length;

/// Rejected bids carry the server price. A higher value replaces the stale one.
num visiblePriceAfterRejection({
  required num visiblePrice,
  required num? rejectedCurrentPrice,
}) {
  if (rejectedCurrentPrice != null && rejectedCurrentPrice > visiblePrice) {
    return rejectedCurrentPrice;
  }
  return visiblePrice;
}

/// Owner of an active cap sees the badge while the visible price has not
/// passed that cap. [visiblePrice] is the on-screen public price.
bool shouldShowAutoBidBadge({
  required bool sellerBlocked,
  required int? sessionUserId,
  required int? productId,
  required num visiblePrice,
  required Iterable<MaxBidModel> bids,
}) {
  if (sellerBlocked) return false;
  final maxAmount = activeOwnMaxAmount(
    sessionUserId: sessionUserId,
    productId: productId,
    bids: bids,
  );
  if (maxAmount == null) return false;
  return visiblePrice <= maxAmount;
}

class AuctionBiddingControlsWidget extends ConsumerStatefulWidget {
  final AuctionModel auction;
  final Function(int qty, num price, int? productId) onPlaceBid;
  final DateTime? expiryDate;
  final bool isAuctionEnded;
  final bool isOwner;
  final int? winnerId;
  final String? winnerName;
  final num? finalPrice;
  final bool isViewOnly;
  final AuctionProducts? selectedProduct;
  final bool showOnlyMaxBid;
  final bool sellerBidBlocked;
  final VoidCallback? onGoToLiveLot;
  final bool suppressSwipe;
  final bool bidPending;
  final num? knownHighestBid;

  /// Live `auctionItemEnded.isSold` for [selectedProduct]. Null means the
  /// server has not decided yet, so the card must not fall back to «لم يبع».
  final bool? lotSoldOverride;

  /// Winner recorded for [selectedProduct] only. The auction-ended winner
  /// must not be painted on a different lot.
  final int? lotWinnerUserId;
  final num? lotWinnerPrice;
  final int? endedLotId;

  const AuctionBiddingControlsWidget({
    super.key,
    required this.auction,
    required this.onPlaceBid,
    this.expiryDate,
    this.isAuctionEnded = false,
    this.isOwner = false,
    this.winnerId,
    this.winnerName,
    this.finalPrice,
    this.isViewOnly = false,
    this.selectedProduct,
    this.showOnlyMaxBid = false,
    this.sellerBidBlocked = false,
    this.onGoToLiveLot,
    this.suppressSwipe = false,
    this.bidPending = false,
    this.knownHighestBid,
    this.lotSoldOverride,
    this.lotWinnerUserId,
    this.lotWinnerPrice,
    this.endedLotId,
  });

  @override
  ConsumerState<AuctionBiddingControlsWidget> createState() =>
      _AuctionBiddingControlsWidgetState();
}

class _AuctionBiddingControlsWidgetState
    extends ConsumerState<AuctionBiddingControlsWidget> {
  //double _selectedMultiplier = 1.0; // 1.0, 1.5, or 2.0
  final TextEditingController _customBidController = TextEditingController();
  final FocusNode _customBidFocus = FocusNode();

  // 0 = Max Bid list, 1 = One Step Bid (pre-auction only)
  int _preAuctionTab = 0;
  int _selectedMaxBidIndex = 0;
  FixedExtentScrollController? _maxBidScrollController;
  List<num> _memoizedBidSteps = const [];
  num? _memoizedBidStepsBase;
  int? _memoizedBidStepsProductId;
  DateTime? _effectiveExpiry;
  bool _lotExpired = false;
  num? _acceptedOwnMax;
  bool _suppressServerMax = false;
  num? _rejectedPriceFloor;
  num? _acceptedVisiblePrice;
  int? _ackLeaderUserId;
  bool _ackOutbid = false;
  LiveLotPaint? _lotPaint;

  @override
  void initState() {
    super.initState();
    _maxBidScrollController = FixedExtentScrollController(initialItem: 0);
    _syncExpiryFromWidget();
  }

  @override
  void didUpdateWidget(covariant AuctionBiddingControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final productChanged =
        oldWidget.selectedProduct?.id != widget.selectedProduct?.id;
    final timerChanged =
        oldWidget.auction.expiryDate != widget.auction.expiryDate ||
        oldWidget.expiryDate != widget.expiryDate ||
        oldWidget.auction.liveStartDate != widget.auction.liveStartDate ||
        oldWidget.auction.isPreAuction != widget.auction.isPreAuction;
    if (shouldClearAcceptedBidState(productChanged: productChanged)) {
      _acceptedOwnMax = null;
      _suppressServerMax = false;
      _rejectedPriceFloor = null;
      _acceptedVisiblePrice = null;
      _ackLeaderUserId = null;
      _ackOutbid = false;
      _lotPaint = null;
    }
    if (productChanged || timerChanged) {
      _lotExpired = false;
      _syncExpiryFromWidget();
    }
  }

  void _commitPaint(LiveLotPaintResult result) {
    _lotPaint = result.paint;
    _acceptedOwnMax = result.paint.ownMax;
    _suppressServerMax = result.paint.suppressOwnMax;
    _acceptedVisiblePrice = result.paint.price;
    _ackLeaderUserId = result.paint.leaderUserId;
    _ackOutbid = result.paint.leaderUserId != null &&
        result.paint.userParticipated &&
        result.paint.leaderUserId != CachedVariables.userId;
  }

  void _syncExpiryFromWidget() {
    if (widget.auction.isPreAuction && widget.auction.liveStartDate != null) {
      _effectiveExpiry = widget.auction.liveStartDate;
    } else {
      _effectiveExpiry = widget.expiryDate ?? widget.auction.expiryDate;
    }
    _lotExpired = _computeLotExpired();
  }

  bool _computeLotExpired() {
    if (widget.auction.isPreAuction) return false;
    final viewingLiveOpen = isCurrentLiveLot(
          productId: widget.selectedProduct?.id,
          productName: widget.selectedProduct?.displayName,
          currentProductId: widget.auction.currentProductId,
          currentProductName: widget.auction.currentProduct,
        ) &&
        !isCurrentLiveLotClosedByServer(
          isAuctionEnded: widget.isAuctionEnded,
          auctionExpired: widget.auction.isExpired,
          auctionCanceled: widget.auction.isCanceled,
          productSold: widget.selectedProduct?.isSold,
          productExpired: widget.selectedProduct?.isExpired,
        );
    if (viewingLiveOpen) return false;
    final expiry = _effectiveExpiry;
    if (expiry == null) return true;
    return !serverClock.nowDate().isBefore(expiry);
  }

  List<num> _bidStepsFor(num basePrice, int? productId) {
    if (_memoizedBidStepsBase == basePrice &&
        _memoizedBidStepsProductId == productId &&
        _memoizedBidSteps.length == 50) {
      return _memoizedBidSteps;
    }
    final bool isBaseChanged =
        _memoizedBidStepsBase != null &&
        (_memoizedBidStepsBase != basePrice ||
            _memoizedBidStepsProductId != productId);
    _memoizedBidStepsBase = basePrice;
    _memoizedBidStepsProductId = productId;
    _memoizedBidSteps = buildBidSteps(basePrice, 50, productId: productId);
    final maxIndex = _memoizedBidSteps.isEmpty
        ? 0
        : _memoizedBidSteps.length - 1;
    if (isBaseChanged || _selectedMaxBidIndex > maxIndex) {
      _selectedMaxBidIndex = 0;
      _jumpPickerIfNeeded();
    }
    return _memoizedBidSteps;
  }

  void _jumpPickerIfNeeded() {
    final controller = _maxBidScrollController;
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!controller.hasClients) return;
      if (controller.selectedItem != _selectedMaxBidIndex) {
        controller.jumpToItem(_selectedMaxBidIndex);
      }
    });
  }

  @override
  void dispose() {
    _maxBidScrollController?.dispose();
    _customBidController.dispose();
    _customBidFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auctionProduct = ref.watch(auctionProductChangeProvider);
    final lastBid = ref.watch(currentBidStateProvider);
    final latestExpiry = ref.watch(latestExpiryDateStateProvider);
    final ordersValue = ref.watch(
      getUserOrdersProvider(CachedVariables.userId ?? 0),
    );
    final orders = ordersValue.value ?? [];

    ref.listen(newBidEventProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      final openProductId =
          widget.selectedProduct?.id ?? widget.auction.currentProductId;
      if (event.eventProductId != null &&
          openProductId != null &&
          event.eventProductId != openProductId) {
        return;
      }
      final rows = event.auctionBids.isNotEmpty
          ? event.auctionBids
          : <AuctionBid>[if (event.newBid != null) event.newBid!];
      final result = applyLiveLotPaint(
        current: _lotPaint,
        incoming: LiveLotPaintInput(
          fromAccepted: false,
          productId: event.eventProductId,
          bidId: event.newBid?.id,
          leaderUserId: event.newBid?.userId,
          price: event.currentPrice ?? event.newBid?.bid,
          confrontation: visibleConfrontationCount(rows),
          sessionUserId: CachedVariables.userId,
          participantIds: [
            for (final bid in rows)
              if (bid.userId != null) bid.userId!,
          ],
        ),
      );
      setState(() {
        if (event.expiryDate != null) {
          _effectiveExpiry = event.expiryDate;
          _lotExpired = _computeLotExpired();
        }
        _commitPaint(result);
      });
      if (openProductId != null && event.eventProductId == openProductId) {
        ref.invalidate(userMaxBidsProvider);
      }
    });
    ref.listen(bidAcceptedProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      final openProductId =
          widget.selectedProduct?.id ?? widget.auction.currentProductId;
      if (openProductId != null &&
          event.productId != null &&
          event.productId != openProductId) {
        return;
      }
      final result = applyLiveLotPaint(
        current: _lotPaint,
        incoming: LiveLotPaintInput(
          fromAccepted: true,
          productId: event.productId,
          bidId: event.leaderBidId,
          leaderUserId: event.leaderUserId,
          price: event.currentPrice,
          confrontation: visibleConfrontationCount(event.auctionBids),
          explicitOutbid: event.outbid,
          submittedAmount: event.submittedAmount ?? event.amount,
          sessionUserId: CachedVariables.userId,
          participantIds: [
            for (final bid in event.auctionBids)
              if (bid.userId != null) bid.userId!,
          ],
        ),
      );
      setState(() => _commitPaint(result));
      ref.invalidate(userMaxBidsProvider);
    });
    ref.listen(bidRejectedProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      final openProductId = widget.selectedProduct?.id;
      if (openProductId != null &&
          event.productId != null &&
          event.productId != openProductId) {
        return;
      }
      final price = event.currentPrice;
      if (price == null || price <= 0) return;
      if (_rejectedPriceFloor != null && price <= _rejectedPriceFloor!) return;
      setState(() => _rejectedPriceFloor = price);
    });
    ref.listen(timerExtendedEventProvider, (previous, next) {
      final expiryDateTime = next.valueOrNull?.expiryDate;
      if (expiryDateTime == null) return;
      setState(() {
        _effectiveExpiry = expiryDateTime;
        _lotExpired = _computeLotExpired();
      });
    });

    // Check if the timer needs to be refreshed using the latest known global expiry date
    // from the socket, if the bottom sheet was just opened and we missed the event.
    if (latestExpiry != null && latestExpiry != _effectiveExpiry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (latestExpiry == _effectiveExpiry) return;
        setState(() {
          _effectiveExpiry = latestExpiry;
          _lotExpired = _computeLotExpired();
        });
      });
    }

    // Find the current product ID to filter bids correctly
    // This prevents using bids from a previous item when joining a running auction
    int? currentProductId =
        widget.selectedProduct?.id ?? widget.auction.currentProductId;
    if (currentProductId == null &&
        widget.auction.currentProduct != null &&
        widget.auction.auctionProducts != null) {
      final match = widget.auction.auctionProducts!.firstWhere(
        (p) => p.displayName == widget.auction.currentProduct,
        orElse: () => AuctionProducts(),
      );
      currentProductId = match.id;
    }

    // Platform contract: bidPrice = public starting/opening; minBidPrice = reserve.
    // Increment comes from getIncrementForPrice (same ladder as the server).
    // Product 3833 (auction 4 lot 12) caps the 500 tier at 200.
    num openingPrice = openingPriceFromAuction(
      auctionBidPrice: widget.auction.bidPrice,
      selectedProduct: widget.selectedProduct,
    );

    // Determine the latest bid from either real-time update or initial data
    // Filter initial bids by the current product to avoid using bids from previous items
    final catalogBids = bidsForSelectedLot(
      productBids: widget.selectedProduct?.bids,
      auctionBids: widget.auction.auctionBids,
      productId: currentProductId,
    );
    final AuctionBid? latestBid = (() {
      // Prefer real-time bid if it matches the current product
      if (lastBid != null &&
          lastBid.isActive != false &&
          (currentProductId == null || lastBid.productId == currentProductId)) {
        return lastBid;
      }

      // Fall back to the highest public bid. Inactive rows are hidden max bids,
      // not the current price (a 5000 ceiling must not turn a 3100 lot into 5200).
      if (catalogBids.isNotEmpty) {
        final publicBids = catalogBids.where((b) => b.isActive != false).toList();

        if (publicBids.isNotEmpty) {
          final sorted = [...publicBids]
            ..sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0));
          return sorted.first;
        }
      }
      return null;
    })();

    // Check if there's a recent bid rejection that provides a newer server price
    final lastRejectionEvent = ref.watch(bidRejectedProvider).valueOrNull;
    num? rejectedServerPrice;
    if (lastRejectionEvent != null &&
        (currentProductId == null ||
            lastRejectionEvent.productId == currentProductId)) {
      rejectedServerPrice = lastRejectionEvent.currentPrice;
    }

    // Current price logic:
    // 1. Real-time update (lastBid for current product) OR Server price from rejection
    // 2. Highest bid from history for current product
    // 3. Opening price
    num currentPrice = openingPrice;
    if (latestBid != null) {
      currentPrice = latestBid.bid ?? openingPrice;
    }
    currentPrice = highestVisibleBid(
      openingPrice: currentPrice,
      knownHighest: widget.knownHighestBid,
    );
    // If a rejection informed us of a higher price, use it for the number and ladder.
    currentPrice = visiblePriceAfterRejection(
      visiblePrice: currentPrice,
      rejectedCurrentPrice: rejectedServerPrice,
    );
    currentPrice = visiblePriceAfterRejection(
      visiblePrice: currentPrice,
      rejectedCurrentPrice: _rejectedPriceFloor,
    );
    currentPrice = visiblePriceAfterAccept(
      visiblePrice: currentPrice,
      acceptedCurrentPrice: _acceptedVisiblePrice,
    );
    if (widget.auction.isLive == true) {
      currentPrice = visiblePriceAfterAccept(
        visiblePrice: currentPrice,
        acceptedCurrentPrice: widget.auction.liveCurrentPrice,
      );
    }

    if (auctionProduct != null && widget.selectedProduct == null) {
      // Socket change event: opening is bidPrice only — never reserve.
      if (auctionProduct.bidPrice > 0) {
        openingPrice = auctionProduct.bidPrice;
      }
      // If product changed, reset to opening price unless there's a new bid
      if (lastBid == null) {
        currentPrice = openingPrice;
      }
    }

    final selectedId = widget.selectedProduct?.id;
    final closingLot = selectedId != null &&
        widget.endedLotId != null &&
        selectedId == widget.endedLotId;
    // After the auction ends, a different lot keeps its own bid. The last
    // live price and the hammer belong to the lot that just closed.
    final priceForHeader = widget.isAuctionEnded &&
            selectedId != null &&
            !closingLot
        ? (latestBid?.bid ?? openingPrice)
        : currentPrice;
    currentPrice = headerPriceForSelectedLot(
      lotPrice: priceForHeader,
      auctionEnded: widget.isAuctionEnded,
      auctionFinalPrice: widget.finalPrice,
      selectedLotId: selectedId,
      endedLotId: widget.endedLotId,
    );

    // Determine if the auction has truly ended based on explicit flags.
    // The parent widget (LiveAuctionScreen) sets isAuctionEnded via socket events.
    final bool isAuctionEnded =
        widget.isAuctionEnded ||
        widget.auction.isExpired == true ||
        widget.auction.isCanceled == true;

    // Hide swipe-to-bid only when the server closed this lot. A local timer
    // of 0 must not show «لم تُبع» on the current live item.
    final bool isBiddingDisabled = isCurrentLiveLotClosedByServer(
      isAuctionEnded: isAuctionEnded,
      auctionExpired: widget.auction.isExpired,
      auctionCanceled: widget.auction.isCanceled,
      productSold: widget.selectedProduct?.isSold,
      productExpired: widget.selectedProduct?.isExpired,
    );

    // Check if the auction has actually started (reached startDate)
    final bool hasStarted =
        widget.auction.startDate == null ||
        !serverClock.nowDate().isBefore(widget.auction.startDate!);

    // Bidding is allowed if the auction has started and not ended
    final bool auctionNotStarted = !hasStarted;

    // Filter all bids to just the ones for the current product
    // Start with initial bids from the API
    final List<AuctionBid> initialProductBids = currentProductId != null
        ? catalogBids
              .where(
                (bid) => bid.productId == null || bid.productId == currentProductId,
              )
              .toList()
        : catalogBids;

    // Merge in accumulated socket bids for the current product
    final socketBids = ref.watch(accumulatedBidsProvider);
    final filteredSocketBids = socketBids
        .where(
          (b) => currentProductId == null || b.productId == currentProductId,
        )
        .toList();

    // Deduplicate: socket bids take priority over initial bids with the same ID
    final socketBidIds = <int>{};
    for (final b in filteredSocketBids) {
      if (b.id != null) socketBidIds.add(b.id!);
    }
    final List<AuctionBid> currentProductBids = <AuctionBid>[
      ...filteredSocketBids,
      ...initialProductBids.where(
        (b) => b.id == null || !socketBidIds.contains(b.id),
      ),
    ];

    // Find the highest user bid vs the highest public bid.
    // A missing isActive flag is a public socket row, not a hidden proxy.
    final AuctionBid? highestBidAny = currentProductBids.isNotEmpty
        ? (List.of(
            currentProductBids,
          )..sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0))).first
        : null;

    final publicBids = currentProductBids
        .where((bid) => bid.isActive != false)
        .toList();
    final AuctionBid? highestActiveBid = publicBids.isNotEmpty
        ? (List.of(publicBids)
              ..sort((a, b) {
                final byAmount = (b.bid ?? 0).compareTo(a.bid ?? 0);
                if (byAmount != 0) return byAmount;
                return (b.id ?? 0).compareTo(a.id ?? 0);
              }))
            .first
        : highestBidAny;

    final bool amountSaysLeader =
        highestActiveBid?.userId == CachedVariables.userId;
    final bool isHighestActiveBidder = sessionUserLeadsLot(
      sessionUserId: CachedVariables.userId,
      leaderUserId: _ackLeaderUserId,
      ackOutbid: _ackOutbid,
      amountSaysLeader: amountSaysLeader,
    );

    // Check if the user has the absolute highest bid, but it's not active yet (proxy bid)
    final bool isHighestBidderInactive = !_ackOutbid &&
        highestBidAny?.userId == CachedVariables.userId &&
        !isHighestActiveBidder;

    // Check if user has participated in the current product's auction
    final bool hasParticipated = currentProductBids.any(
      (bid) => bid.userId == CachedVariables.userId,
    );

    // A user is outbid if they participated but are not the highest bidder (active or inactive)
    final bool hasBeenOutbid = _ackOutbid ||
        (hasParticipated && !isHighestActiveBidder && !isHighestBidderInactive);

    final int bidNumber = _lotPaint != null && _lotPaint!.confrontation > 0
        ? _lotPaint!.confrontation
        : visibleConfrontationCount(currentProductBids);

    final num stepsBase = maxBidFloor(
      highestActiveBid: highestActiveBid?.bid,
      currentPrice: currentPrice,
      openingPrice: openingPrice,
    );
    final List<num> bidSteps = _bidStepsFor(stepsBase, currentProductId);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current Auction Header with Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Bid info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.auctionBidNumber.tr()}${bidNumber.toString().padLeft(3, '0')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  gapH4,
                  // Status indicator
                  if (isHighestActiveBidder)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        gapW4,
                        Text(
                          AppStrings.highestBid.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else if (isHighestBidderInactive)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        gapW4,
                        Text(
                          AppStrings.bidPlacedSuccessfully.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else if (hasBeenOutbid)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8A6A32),
                            shape: BoxShape.circle,
                          ),
                        ),
                        gapW4,
                        Text(
                          AppStrings.higherBidThanYours.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A6A32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              // Right side: Current Auction label and price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.currentAuction.tr(),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      Text(
                        ([
                              highestActiveBid?.bid,
                              currentPrice,
                            ].whereType<num>().reduce((a, b) => a > b ? a : b))
                            .toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      gapW8,
                      SvgPicture.asset(
                        'assets/icons/RSA.svg',
                        width: 28,
                        height: 28,
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          gapH16,

          // Timer pill with progress bar for last 30 seconds
          if (!isAuctionEnded && !widget.auction.isPreAuction) ...[
            AuctionExpiryClock(
              key: ValueKey(
                'lot-clock-${widget.selectedProduct?.id ?? widget.auction.currentProductId ?? 0}-${_effectiveExpiry?.millisecondsSinceEpoch ?? 0}',
              ),
              expiry: _effectiveExpiry,
              durationThreshold: widget.auction.itemDuration ?? 30,
              isAuctionEnded: isAuctionEnded,
              onExpired: () {
                if (!mounted || _lotExpired) return;
                if (isCurrentLiveLot(
                      productId: widget.selectedProduct?.id,
                      productName: widget.selectedProduct?.displayName,
                      currentProductId: widget.auction.currentProductId,
                      currentProductName: widget.auction.currentProduct,
                    ) &&
                    !isCurrentLiveLotClosedByServer(
                      isAuctionEnded: widget.isAuctionEnded,
                      auctionExpired: widget.auction.isExpired,
                      auctionCanceled: widget.auction.isCanceled,
                      productSold: widget.selectedProduct?.isSold,
                      productExpired: widget.selectedProduct?.isExpired,
                    )) {
                  return;
                }
                setState(() => _lotExpired = true);
              },
            ),
            gapH16,
          ],

          if (widget.showOnlyMaxBid) _buildAutoBidBadge(currentPrice),
          if (_sellerCannotBid)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'لا يمكنك المزايدة على هذا البند.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          else if (widget.isViewOnly) ...[
            // Check if user won this specific past product
            Builder(
              builder: (context) {
                if (_isUpcomingSelectedLot()) {
                  return _viewOnlyLotMessage(AppStrings.comingSoon.tr());
                }

                final currentUserId = CachedVariables.userId;
                final productId = widget.selectedProduct?.id;

                if (productId != null) {
                  final lead = leadingLotBid(
                    [
                      for (final bid
                          in widget.selectedProduct?.bids ??
                              const <AuctionBid>[])
                        LotBidRow(
                          id: bid.id,
                          productId: bid.productId ?? productId,
                          userId: bid.userId,
                          amount: bid.bid,
                        ),
                      for (final bid
                          in widget.auction.auctionBids ??
                              const <AuctionBid>[])
                        LotBidRow(
                          id: bid.id,
                          productId: bid.productId,
                          userId: bid.userId,
                          amount: bid.bid,
                        ),
                    ],
                    productId,
                  );
                  final decided = explicitLotSale(
                    eventIsSold: widget.lotSoldOverride,
                    productIsSold: widget.selectedProduct?.isSold,
                    productExpired: widget.selectedProduct?.isExpired,
                  );

                  if (decided == null) {
                    return _goToLiveLotControls();
                  }

                  if (!decided) {
                    final stillLiveOpen = isCurrentLiveLot(
                          productId: widget.selectedProduct?.id,
                          productName: widget.selectedProduct?.displayName,
                          currentProductId: widget.auction.currentProductId,
                          currentProductName: widget.auction.currentProduct,
                        ) &&
                        !isCurrentLiveLotClosedByServer(
                          isAuctionEnded: widget.isAuctionEnded,
                          auctionExpired: widget.auction.isExpired,
                          auctionCanceled: widget.auction.isCanceled,
                          productSold: widget.selectedProduct?.isSold,
                          productExpired: widget.selectedProduct?.isExpired,
                        );
                    if (stillLiveOpen) {
                      return _goToLiveLotControls();
                    }
                    return Column(
                      children: [
                        const LotResultBanner(kind: LotResultKind.unsold),
                        gapH8,
                        _goToLiveLotControls(),
                      ],
                    );
                  }

                  final winnerId = widget.lotWinnerUserId ?? lead.userId;
                  final wonPrice = widget.lotWinnerPrice ?? lead.amount ?? 0;
                  if (winnerId != null && winnerId == currentUserId) {

                      final existingOrder = orders
                          .where(
                            (o) =>
                                o.items.any(
                                  (item) =>
                                      item.auctionProductId == productId ||
                                      item.productId == productId,
                                ) &&
                                o.auctionId == widget.auction.id,
                          )
                          .firstOrNull;

                      final bool showCheckOrder =
                          existingOrder != null &&
                          OrderFlowState.canOpenOrderFromAuction(existingOrder);

                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  AppStrings.youWon.tr(),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                gapH4,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${AppStrings.finalPrice.tr()}: ',
                                      style: const TextStyle(
                                        color: Color(0xFF1B5E20),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${wonPrice.toStringAsFixed(0)} ',
                                      style: const TextStyle(
                                        color: Color(0xFF1B5E20),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SvgPicture.asset(
                                      'assets/icons/RSA.svg',
                                      height: 12,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          gapH12,
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (showCheckOrder &&
                                    existingOrder.items.isNotEmpty) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => OrderDetailsScreen(
                                        order: existingOrder,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final winningModel = WinningAuctionModel(
                                  id: 0,
                                  userId: currentUserId ?? 0,
                                  auctionId: widget.auction.id ?? 0,
                                  product:
                                      widget.selectedProduct?.displayName ?? '',
                                  productId: widget.selectedProduct?.id ?? 0,
                                  price: wonPrice.toDouble(),
                                  sold: false,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  auctionTitle: widget.auction.displayTitle,
                                  auctionStartDate:
                                      widget.auction.startDate ??
                                      DateTime.now(),
                                  winnerName: '',
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderDetailsScreen(
                                          order: OrderModel.fromWinningAuction(
                                            winningModel,
                                          ),
                                        ),
                                  ),
                                );
                              },
                              icon: Icon(
                                showCheckOrder
                                    ? Icons.visibility
                                    : Icons.receipt_long,
                                color: Colors.white,
                              ),
                              label: Text(
                                showCheckOrder
                                    ? AppStrings.checkOrder.tr()
                                    : AppStrings.continueToOrder.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D4739),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      );
                  }
                }

                // Default: not won, show "Not currently live"
                return _viewOnlyLotMessage(AppStrings.ended.tr());
              },
            ),
          ] else if (widget.isOwner) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.youAreAuctionOwner.tr(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (widget.auction.isPreAuction &&
              widget.selectedProduct == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Center(
                child: Text(
                  AppStrings.selectItemToBid.tr(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else if (!isBiddingDisabled) ...[
            // ─────────────────────────────────────────────────
            // PRE-AUCTION: two bidding options
            // ─────────────────────────────────────────────────
            if (widget.auction.isPreAuction) ...[
              // Tab selector
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _preAuctionTab = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _preAuctionTab == 0
                              ? const Color(0xFF2D4739)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _preAuctionTab == 0
                                ? const Color(0xFF2D4739)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AppStrings.maxBid.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _preAuctionTab == 0
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gapW8,
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _preAuctionTab = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _preAuctionTab == 1
                              ? const Color(0xFF2D4739)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _preAuctionTab == 1
                                ? const Color(0xFF2D4739)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AppStrings.oneStepBid.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _preAuctionTab == 1
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              gapH16,

              // Option 1: Max Bid — compact CupertinoPicker
              if (_preAuctionTab == 0) ...[
                // Picker drum-roll
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: CupertinoPicker(
                    scrollController: _maxBidScrollController,
                    itemExtent: 44,
                    onSelectedItemChanged: (i) {
                      setState(() => _selectedMaxBidIndex = i);
                    },
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D4739).withOpacity(0.08),
                        border: const Border.symmetric(
                          horizontal: BorderSide(
                            color: Color(0xFF2D4739),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    children: List.generate(bidSteps.length, (i) {
                      final stepBid = bidSteps[i];
                      return Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${AppStrings.bid.tr()} ${i + 1}  •  ${stepBid.toStringAsFixed(0)} ',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2E22),
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/RSA.svg',
                              height: 12,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF1A2E22),
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                gapH12,
                // Bid button for selected amount
                Builder(
                  builder: (context) {
                    final selectedBid =
                        bidSteps[_selectedMaxBidIndex.clamp(
                          0,
                          bidSteps.length - 1,
                        )];
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (auctionNotStarted || selectedBid <= currentPrice)
                            ? null
                            : () {
                                widget.onPlaceBid(
                                  1,
                                  selectedBid,
                                  currentProductId,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D4739),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${AppStrings.bidNow.tr()} — ${selectedBid.toStringAsFixed(0)} ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/RSA.svg',
                              height: 14,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

              if (_preAuctionTab == 1) ...[
                _buildOneStepBidButton(
                  auctionNotStarted: auctionNotStarted,
                  currentPrice: stepsBase,
                  bidIncrement: getIncrementForPrice(
                    stepsBase,
                    productId: currentProductId,
                  ),
                  currentProductId: currentProductId,
                ),
              ],
            ] else ...[
              // ─────────────────────────────────────────────
              // LIVE AUCTION: one-step bid only
              // ─────────────────────────────────────────────
              _buildOneStepBidButton(
                auctionNotStarted: auctionNotStarted,
                currentPrice: stepsBase,
                bidIncrement: getIncrementForPrice(
                  stepsBase,
                  productId: currentProductId,
                ),
                currentProductId: currentProductId,
              ),
            ],
          ] else
            _buildResultContainer(currentPrice, orders),
        ],
      ),
    );
  }

  bool get _sellerCannotBid =>
      widget.sellerBidBlocked ||
      widget.selectedProduct?.bidBlockedReason == 'SELLER';

  /// Draft copy until the client confirms the final sentence.
  Widget _buildAutoBidBadge(num currentPrice) {
    final bids = ref.watch(userMaxBidsProvider).valueOrNull ?? const [];
    final lotId = widget.selectedProduct?.id ?? widget.auction.currentProductId;
    final maxAmount = visibleOwnMaxAmount(
      acceptedOwnMax: _acceptedOwnMax,
      suppressServerMax: _suppressServerMax,
      sessionUserId: CachedVariables.userId,
      productId: lotId,
      bids: bids,
    );
    if (maxAmount == null || _sellerCannotBid || currentPrice > maxAmount) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        autoBidBadgeSentence(maxAmount),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// One-step bid: swipe-to-bid during live countdown; tap fallback when disabled.
  Widget _buildOneStepBidButton({
    required bool auctionNotStarted,
    required num currentPrice,
    required num bidIncrement,
    required int? currentProductId,
  }) {
    final num nextBid = currentPrice + bidIncrement;
    final bool canBid = !auctionNotStarted && !widget.isAuctionEnded;

    if (!canBid) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D4739),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: Text(
            auctionNotStarted
                ? AppStrings.willStartSoon.tr()
                : AppStrings.ended.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return SwipeToBidBar(
      amountText: nextBid.toStringAsFixed(0),
      hintText: AppStrings.swipeToBid.tr(),
      somLabel: AppStrings.som.tr(),
      showSuccess: widget.suppressSwipe || widget.bidPending,
      successText: widget.bidPending
          ? AppStrings.bidConfirming.tr()
          : AppStrings.bidPlacedSuccessfully.tr(),
      onConfirmed: () => widget.onPlaceBid(1, nextBid, currentProductId),
    );
  }

  Widget _buildResultContainer(num currentPrice, List<OrderModel> orders) {
    final decided = explicitLotSale(
      eventIsSold: widget.lotSoldOverride,
      productIsSold: widget.selectedProduct?.isSold,
      productExpired: widget.selectedProduct?.isExpired,
    );
    final isSold = decided == true;

    final lotStillOpen = !isCurrentLiveLotClosedByServer(
      isAuctionEnded: widget.isAuctionEnded,
      auctionExpired: widget.auction.isExpired,
      auctionCanceled: widget.auction.isCanceled,
      productSold: widget.selectedProduct?.isSold,
      productExpired: widget.selectedProduct?.isExpired,
    );
    final viewingCurrentLive = isCurrentLiveLot(
      productId: widget.selectedProduct?.id,
      productName: widget.selectedProduct?.displayName,
      currentProductId: widget.auction.currentProductId,
      currentProductName: widget.auction.currentProduct,
    );

    if (!isSold) {
      if (decided == null || (lotStillOpen && viewingCurrentLive)) {
        return const SizedBox.shrink();
      }
      return const LotResultBanner(kind: LotResultKind.unsold);
    }

    final selectedId = widget.selectedProduct?.id;
    final globalWinnerIsThisLot = widget.endedLotId == null ||
        selectedId == null ||
        selectedId == widget.endedLotId;
    if (widget.isAuctionEnded &&
        widget.winnerId != null &&
        globalWinnerIsThisLot) {
      final isWinner = widget.winnerId == CachedVariables.userId;
      final finalPrice = widget.finalPrice ?? currentPrice;

      // Find if there's an existing order for this user and product
      final currentProductId =
          widget.selectedProduct?.id ?? widget.auction.currentProductId;
      final existingOrder = orders
          .where(
            (o) =>
                o.items.any(
                  (item) =>
                      item.auctionProductId == currentProductId ||
                      item.productId == currentProductId,
                ) &&
                o.auctionId == widget.auction.id,
          )
          .firstOrNull;

      final bool showCheckOrder =
          existingOrder != null &&
          OrderFlowState.canOpenOrderFromAuction(existingOrder);

      if (isWinner) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Text(
                    AppStrings.youWon.tr(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  gapH4,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${'finalPrice'.tr()}: ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${finalPrice.toStringAsFixed(0)} ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icons/RSA.svg',
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Colors.green,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            gapH12,
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (showCheckOrder) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailsScreen(order: existingOrder),
                      ),
                    );
                    return;
                  }

                  final winningModel = WinningAuctionModel(
                    id: 0,
                    userId: CachedVariables.userId ?? 0,
                    auctionId: widget.auction.id ?? 0,
                    product: widget.auction.currentProduct ?? '',
                    productId: currentProductId ?? 0,
                    price: finalPrice.toDouble(),
                    sold: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    auctionTitle: widget.auction.displayTitle,
                    auctionStartDate:
                        widget.auction.startDate ?? DateTime.now(),
                    winnerName: '',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(
                        order: OrderModel.fromWinningAuction(winningModel),
                      ),
                    ),
                  );
                },
                icon: Icon(
                  showCheckOrder ? Icons.visibility : Icons.receipt_long,
                  color: Colors.white,
                ),
                label: Text(
                  showCheckOrder
                      ? 'Check the Order'
                      : AppStrings.continueToOrder.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D4739),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        );
      } else {
        // Did the user bid? We can check locally via the `auction.auctionBids` or just
        // generic logic. For now, if we lost, we lost.
        // But if we never bid, "You Lost" might feel aggressive?
        // Let's check if the user is in the bid list if available.
        // Similar logic to AuctionGallery.
        final currentProductBids = currentProductId != null
            ? (widget.auction.auctionBids
                      ?.where((bid) => bid.productId == currentProductId)
                      .toList() ??
                  [])
            : (widget.auction.auctionBids ?? []);

        final bool userBid = currentProductBids.any(
          (bid) => bid.userId == CachedVariables.userId,
        );

        if (userBid) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E22).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8A6A32)),
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.youLost.tr(),
                  style: const TextStyle(
                    color: Color(0xFF1A2E22),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                gapH4,
                if (widget.winnerName != null)
                  Text(
                    '${'winner'.tr()}: ${widget.winnerName}',
                    style: const TextStyle(color: Color(0xFF5C4A32), fontSize: 14),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${'finalPrice'.tr()}: ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E22),
                      ),
                    ),
                    Text(
                      '${finalPrice.toStringAsFixed(0)} ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2E22),
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/RSA.svg',
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1A2E22),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.auctionEnded.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                gapH4,
                if (widget.winnerName != null)
                  Text(
                    '${'winner'.tr()}: ${widget.winnerName}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${'finalPrice'.tr()}: ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${finalPrice.toStringAsFixed(0)} ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/RSA.svg',
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Colors.grey.shade700,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  bool _isUpcomingSelectedLot() {
    final products = widget.auction.auctionProducts;
    if (products == null || products.isEmpty) return false;
    return isUpcomingLiveLot(
      productIdsInOrder: products.map((p) => p.id).toList(),
      selectedProductId: widget.selectedProduct?.id,
      currentProductId: widget.auction.currentProductId,
    );
  }

  Widget _viewOnlyLotMessage(String title) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        gapH8,
        _goToLiveLotControls(),
      ],
    );
  }

  Widget _goToLiveLotControls() {
    return Column(
      children: [
        Text(
          AppStrings.bidOnlyOnLiveLot.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (widget.onGoToLiveLot != null) ...[
          gapH8,
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: widget.onGoToLiveLot,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D4739),
                side: const BorderSide(color: Color(0xFF2D4739)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppStrings.goToLiveLot.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  //Widget _buildBidMultiplierButton({
  //  required double multiplier,
  //  required num bidIncrement,
  //  required num currentPrice,
  //  required bool isDisabled,
  //}) {
  //  final bool isSelected = _selectedMultiplier == multiplier;
  //  // Calculate total bid price (current + increment * multiplier)
  //  final num totalBidPrice = currentPrice + (bidIncrement * multiplier);
  //  final String label = '\$${totalBidPrice.toStringAsFixed(0)}';

  //  return GestureDetector(
  //    onTap: isDisabled
  //        ? null
  //        : () {
  //            setState(() {
  //              _selectedMultiplier = multiplier;
  //            });
  //          },
  //    child: AnimatedContainer(
  //      duration: const Duration(milliseconds: 200),
  //      padding: const EdgeInsets.symmetric(vertical: 12),
  //      decoration: BoxDecoration(
  //        color: isSelected ? const Color(0xFF2D4739) : Colors.white,
  //        borderRadius: BorderRadius.circular(8),
  //        border: Border.all(
  //          color: isDisabled
  //              ? Colors.grey.shade300
  //              : (isSelected ? const Color(0xFF2D4739) : Colors.grey.shade400),
  //          width: isSelected ? 2 : 1,
  //        ),
  //      ),
  //      child: Center(
  //        child: Text(
  //          label,
  //          style: TextStyle(
  //            fontSize: 14,
  //            fontWeight: FontWeight.bold,
  //            color: isDisabled
  //                ? Colors.grey
  //                : (isSelected ? Colors.white : Colors.black87),
  //          ),
  //        ),
  //      ),
  //    ),
  //  );
  //}
}

