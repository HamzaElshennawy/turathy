import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/domain/winning_auction_model.dart';
import 'package:turathy/src/features/orders/presentation/order_details_screen.dart';
import 'package:turathy/src/features/orders/domain/order_flow_state.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';

import 'package:turathy/src/core/helper/socket/socket_exports.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';

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
  });

  @override
  ConsumerState<AuctionBiddingControlsWidget> createState() =>
      _AuctionBiddingControlsWidgetState();
}

class _AuctionBiddingControlsWidgetState
    extends ConsumerState<AuctionBiddingControlsWidget> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  //double _selectedMultiplier = 1.0; // 1.0, 1.5, or 2.0
  final TextEditingController _customBidController = TextEditingController();
  final FocusNode _customBidFocus = FocusNode();

  // 0 = Max Bid list, 1 = One Step Bid (pre-auction only)
  int _preAuctionTab = 0;
  int _selectedMaxBidIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void didUpdateWidget(covariant AuctionBiddingControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auction.expiryDate != widget.auction.expiryDate ||
        oldWidget.expiryDate != widget.expiryDate ||
        oldWidget.auction.liveStartDate != widget.auction.liveStartDate ||
        oldWidget.auction.isPreAuction != widget.auction.isPreAuction) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    _timer?.cancel();

    DateTime? expiry;
    if (widget.auction.isPreAuction && widget.auction.liveStartDate != null) {
      expiry = widget.auction.liveStartDate;
    } else {
      // In case the widget is rebuilt, we check if the newBidEventProvider
      // has a newer expiryDate, although we usually listen to it in build().
      // For initialization, we rely on the passed widget.expiryDate or widget.auction.expiryDate.
      expiry = widget.expiryDate ?? widget.auction.expiryDate;
    }

    if (expiry != null) {
      final expiryDateTime = expiry;
      _updateRemainingTime(expiryDateTime);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemainingTime(expiryDateTime);
      });
    }
  }

  void _updateRemainingTime(DateTime expiryDateTime) {
    final now = DateTime.now();
    final difference = expiryDateTime.difference(now);

    if (mounted) {
      setState(() {
        _remainingTime = difference.isNegative ? Duration.zero : difference;
      });
    }

    if (difference.inSeconds <= 0) {
      _timer?.cancel();
    }
  }

  String _formatDuration(Duration duration) {
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else if (duration.inMinutes > 0) {
      return '$minutes:$seconds';
    } else {
      return '${duration.inSeconds} sec';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _customBidController.dispose();
    _customBidFocus.dispose();
    super.dispose();
  }

  /// Returns the correct bid increment for a given price, matching the
  /// server-side thresholds so the bid list never proposes an invalid step.
  static num _getIncrementForPrice(num price) {
    if (price < 500) return 10;
    if (price < 1500) return 20;
    if (price < 3000) return 50;
    if (price < 5000) return 100;
    if (price < 7500) return 200;
    return 500;
  }

  /// Builds a list of [count] bid amounts starting from [basePrice],
  /// recalculating the increment at each step so threshold crossings are
  /// respected (e.g. 1480 +20 = 1500, then 1500 +50 = 1550, not +20).
  static List<num> _buildBidSteps(num basePrice, int count) {
    final steps = <num>[];
    num running = basePrice;
    for (int i = 0; i < count; i++) {
      final inc = _getIncrementForPrice(running);
      running += inc;
      steps.add(running);
    }
    return steps;
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
      if (event?.expiryDate != null) {
        _timer?.cancel();
        final expiryDateTime = event!.expiryDate!;
        _updateRemainingTime(expiryDateTime);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateRemainingTime(expiryDateTime);
        });
      }
    });

    // Check if the timer needs to be refreshed using the latest known global expiry date
    // from the socket, if the bottom sheet was just opened and we missed the event.
    if (latestExpiry != null && _remainingTime == Duration.zero) {
      // Only run this once to pick up the missed expiry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _timer?.cancel();
          _updateRemainingTime(latestExpiry);
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            _updateRemainingTime(latestExpiry);
          });
        }
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

    // bidPrice is the minimum bid increment, not the current price
    num bidIncrement = widget.auction.bidPrice ?? 0;
    // minBidPrice is the opening price (starting price)
    num openingPrice = widget.auction.minBidPrice ?? 0;

    if (widget.selectedProduct != null) {
      if (widget.selectedProduct!.bidPrice != null) {
        bidIncrement =
            num.tryParse(widget.selectedProduct!.bidPrice!) ?? bidIncrement;
      }
      if (widget.selectedProduct!.minBidPrice != null) {
        openingPrice =
            num.tryParse(widget.selectedProduct!.minBidPrice!) ?? openingPrice;
      }
    }

    // Determine the latest bid from either real-time update or initial data
    // Filter initial bids by the current product to avoid using bids from previous items
    final AuctionBid? latestBid = (() {
      // Prefer real-time bid if it matches the current product
      if (lastBid != null &&
          (currentProductId == null || lastBid.productId == currentProductId)) {
        return lastBid;
      }

      // Fall back to the highest bid from history for the current product
      if (widget.auction.auctionBids != null &&
          widget.auction.auctionBids!.isNotEmpty) {
        final productBids = currentProductId != null
            ? widget.auction.auctionBids!
                  .where((b) => b.productId == currentProductId)
                  .toList()
            : widget.auction.auctionBids!;

        if (productBids.isNotEmpty) {
          // Sort descending by bid amount to get the highest
          final sorted = [...productBids]
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
    // If a rejection informed us of a higher price, use it
    if (rejectedServerPrice != null && rejectedServerPrice > currentPrice) {
      currentPrice = rejectedServerPrice;
    }

    if (auctionProduct != null && widget.selectedProduct == null) {
      bidIncrement = auctionProduct.bidPrice;
      openingPrice = auctionProduct.minBidPrice;
      // If product changed, reset to opening price unless there's a new bid
      if (lastBid == null) {
        currentPrice = openingPrice;
      }
    }

    if (widget.isAuctionEnded && widget.finalPrice != null) {
      currentPrice = widget.finalPrice!;
    }

    // Dynamic bid increment logic based on the current price
    bidIncrement = _getIncrementForPrice(currentPrice);

    // Determine if the auction has truly ended based on the model or current time vs expiry
    final bool isTrulyEnded =
        widget.isAuctionEnded ||
        widget.auction.isExpired == true ||
        widget.auction.isCanceled == true ||
        (widget.auction.expiryDate != null &&
            DateTime.now().isAfter(widget.auction.expiryDate!));

    // Reaching zero on the timer only means "ended" if we aren't in pre-auction anymore
    // (In pre-auction, zero means "starting live")
    final bool isAuctionEnded =
        isTrulyEnded ||
        (!widget.auction.isPreAuction && _remainingTime == Duration.zero);

    // Check if the auction has actually started (reached startDate)
    final bool hasStarted =
        widget.auction.startDate == null ||
        DateTime.now().isAfter(widget.auction.startDate!);

    // Bidding is allowed if the auction has started and not ended
    final bool auctionNotStarted = !hasStarted;

    // Filter all bids to just the ones for the current product
    // Start with initial bids from the API
    final List<AuctionBid> initialProductBids = currentProductId != null
        ? (widget.auction.auctionBids
                  ?.where((bid) => bid.productId == currentProductId)
                  .toList() ??
              [])
        : (widget.auction.auctionBids ?? []);

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

    // Find the highest user bid vs the highest active bid
    final AuctionBid? highestBidAny = currentProductBids.isNotEmpty
        ? (List.of(
            currentProductBids,
          )..sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0))).first
        : null;

    final AuctionBid? highestActiveBid =
        currentProductBids.where((b) => b.isActive == true).isNotEmpty
        ? (List.of(
            currentProductBids.where((b) => b.isActive == true),
          )..sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0))).first
        : highestBidAny;

    // Determine the user's status
    final bool isHighestActiveBidder =
        highestActiveBid?.userId == CachedVariables.userId;

    // Check if the user has the absolute highest bid, but it's not active yet (proxy bid)
    final bool isHighestBidderInactive =
        highestBidAny?.userId == CachedVariables.userId &&
        !isHighestActiveBidder;

    // Check if user has participated in the current product's auction
    final bool hasParticipated = currentProductBids.any(
      (bid) => bid.userId == CachedVariables.userId,
    );

    // A user is outbid if they participated but are not the highest bidder (active or inactive)
    final bool hasBeenOutbid =
        hasParticipated && !isHighestActiveBidder && !isHighestBidderInactive;

    final int bidNumber = currentProductBids.length;

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
                        const Text(
                          // Using a string here, but typically you'd add this to AppStrings
                          'Your max bid is registered',
                          style: TextStyle(
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
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        gapW4,
                        Text(
                          AppStrings.higherBidThanYours.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
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
            Builder(
              builder: (context) {
                final num durationThreshold = widget.auction.itemDuration ?? 30;
                final bool showProgressBar =
                    _remainingTime.inSeconds <= durationThreshold &&
                    _remainingTime.inSeconds > 0;
                final double progress = showProgressBar
                    ? _remainingTime.inSeconds / durationThreshold.toDouble()
                    : 0.0;

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Progress bar (only visible in last 30 seconds)
                      if (showProgressBar)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: MediaQuery.of(context).size.width * progress,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _remainingTime.inSeconds <= 10
                                  ? [
                                      const Color(0xFFD32F2F).withAlpha(180),
                                      const Color(0xFFFF5252).withAlpha(150),
                                    ]
                                  : [
                                      const Color(0xFF2D4739).withAlpha(180),
                                      const Color(0xFF4CAF50).withAlpha(150),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      // Timer text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            _formatDuration(_remainingTime),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: showProgressBar
                                  ? Colors.black
                                  : (isAuctionEnded
                                        ? Colors.red
                                        : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            gapH16,
          ],

          // Quick Bid Buttons - 1x, 1.5x, 2x minBid
          if (widget.isViewOnly) ...[
            // Check if user won this specific past product
            Builder(
              builder: (context) {
                final currentUserId = CachedVariables.userId;
                final productId = widget.selectedProduct?.id;

                if (productId != null && widget.auction.auctionBids != null) {
                  final productBids = widget.auction.auctionBids!
                      .where((b) => b.productId == productId)
                      .toList();

                  if (productBids.isNotEmpty) {
                    productBids.sort(
                      (a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0),
                    );
                    final highestBid = productBids.first;

                    if (highestBid.userId == currentUserId) {
                      // User won this product! Show upload receipt
                      final wonPrice = highestBid.bid ?? 0;

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
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${wonPrice.toStringAsFixed(0)} ',
                                      style: const TextStyle(
                                        color: Colors.white,
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
                }

                // Default: not won, show "Not currently live"
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.ended.tr(),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
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
          ] else if (!isAuctionEnded) ...[
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
                    scrollController: FixedExtentScrollController(
                      initialItem: _selectedMaxBidIndex,
                    ),
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
                    children: (() {
                      final steps = _buildBidSteps(
                        (highestActiveBid?.bid ?? currentPrice),
                        10,
                      );
                      return List.generate(steps.length, (i) {
                        final stepBid = steps[i];
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
                      });
                    })(),
                  ),
                ),
                gapH12,
                // Bid button for selected amount
                Builder(
                  builder: (context) {
                    final steps = _buildBidSteps(
                      (highestActiveBid?.bid ?? currentPrice),
                      10,
                    );
                    final selectedBid =
                        steps[_selectedMaxBidIndex.clamp(0, steps.length - 1)];
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auctionNotStarted
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
                  currentPrice: (highestActiveBid?.bid ?? currentPrice),
                  bidIncrement: bidIncrement,
                  currentProductId: currentProductId,
                ),
              ],
            ] else ...[
              // ─────────────────────────────────────────────
              // LIVE AUCTION: one-step bid only
              // ─────────────────────────────────────────────
              _buildOneStepBidButton(
                auctionNotStarted: auctionNotStarted,
                currentPrice: (highestActiveBid?.bid ?? currentPrice),
                bidIncrement: bidIncrement,
                currentProductId: currentProductId,
              ),
            ],
          ] else
            _buildResultContainer(currentPrice, orders),
        ],
      ),
    );
  }

  /// One-step bid button: places a bid of currentPrice + bidIncrement.
  Widget _buildOneStepBidButton({
    required bool auctionNotStarted,
    required num currentPrice,
    required num bidIncrement,
    required int? currentProductId,
  }) {
    final num nextBid = currentPrice + bidIncrement;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: auctionNotStarted
            ? null
            : () {
                widget.onPlaceBid(1, nextBid, currentProductId);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D4739),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              auctionNotStarted
                  ? AppStrings.willStartSoon.tr()
                  : '${AppStrings.bidNow.tr()} — ${nextBid.toStringAsFixed(0)} ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!auctionNotStarted)
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
  }

  Widget _buildResultContainer(num currentPrice, List<OrderModel> orders) {
    if (widget.isAuctionEnded && widget.winnerId != null) {
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
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.youLost.tr(),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                gapH4,
                if (widget.winnerName != null)
                  Text(
                    '${'winner'.tr()}: ${widget.winnerName}',
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${'finalPrice'.tr()}: ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '${finalPrice.toStringAsFixed(0)} ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/RSA.svg',
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
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
      // No winner (expired/cancelled)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Center(
          child: Text(
            AppStrings.auctionEnded.tr(),
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
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
