import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/domain/winning_auction_model.dart';
import 'package:turathy/src/features/orders/presentation/order_confirmation_screen.dart';
import 'package:turathy/src/features/orders/presentation/order_details_screen.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
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
  double _selectedMultiplier = 1.0; // 1.0, 1.5, or 2.0
  final TextEditingController _customBidController = TextEditingController();
  final FocusNode _customBidFocus = FocusNode();

  // Track the user's max bids set during this session per product ID
  final Map<int, double> _userMaxBids = {};

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

    if (difference.isNegative) {
      _timer?.cancel();
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes.toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
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

  @override
  Widget build(BuildContext context) {
    final auctionProduct = ref.watch(auctionProductChangeProvider);
    final lastBid = ref.watch(currentBidStateProvider);
    final ordersValue = ref.watch(
      getUserOrdersProvider(CachedVariables.userId ?? 0),
    );
    final orders = ordersValue.value ?? [];

    final maxBidsValue = ref.watch(userMaxBidsProvider);
    final remoteMaxBids = maxBidsValue.value ?? [];

    // Find the current product ID to filter bids correctly
    // This prevents using bids from a previous item when joining a running auction
    int? currentProductId =
        widget.selectedProduct?.id ?? widget.auction.currentProductId;
    if (currentProductId == null &&
        widget.auction.currentProduct != null &&
        widget.auction.auctionProducts != null) {
      final match = widget.auction.auctionProducts!.firstWhere(
        (p) => p.product == widget.auction.currentProduct,
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

    // Current price logic:
    // 1. Real-time update (lastBid for current product)
    // 2. Highest bid from history for current product
    // 3. Opening price
    num currentPrice = latestBid?.bid ?? openingPrice;

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
    if (currentPrice <= 500) {
      bidIncrement = 10;
    } else if (currentPrice <= 1500) {
      bidIncrement = 20;
    } else if (currentPrice <= 3000) {
      bidIncrement = 50;
    } else if (currentPrice <= 5000) {
      bidIncrement = 100;
    } else if (currentPrice <= 7500) {
      bidIncrement = 200;
    } else {
      bidIncrement = 500;
    }

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
    final List<AuctionBid> currentProductBids = currentProductId != null
        ? (widget.auction.auctionBids
                  ?.where((bid) => bid.productId == currentProductId)
                  .toList() ??
              [])
        : (widget.auction.auctionBids ?? []);

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
                        (highestActiveBid?.bid ?? currentPrice).toStringAsFixed(
                          0,
                        ),
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
          if (!isAuctionEnded) ...[
            Builder(
              builder: (context) {
                final bool showProgressBar =
                    _remainingTime.inSeconds <= 30 &&
                    _remainingTime.inSeconds > 0;
                final double progress = showProgressBar
                    ? _remainingTime.inSeconds / 30.0
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
                                (o.auctionProductId == productId ||
                                    o.productId == productId) &&
                                o.auctionId == widget.auction.id,
                          )
                          .firstOrNull;

                      final bool showCheckOrder =
                          existingOrder != null &&
                          (existingOrder.orderStatus == 'confirmed' ||
                              existingOrder.orderStatus == 'pending_approval');

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
                                Text(
                                  '${AppStrings.finalPrice.tr()}: \$${wonPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
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
                                if (showCheckOrder && existingOrder != null) {
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
                                      widget.selectedProduct?.product ?? '',
                                  productId: widget.selectedProduct?.id ?? 0,
                                  price: wonPrice.toDouble(),
                                  sold: false,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  auctionTitle: widget.auction.title ?? '',
                                  auctionStartDate:
                                      widget.auction.startDate ??
                                      DateTime.now(),
                                  winnerName: '',
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderConfirmationScreen(
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
            if (!auctionNotStarted && !widget.showOnlyMaxBid) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildBidMultiplierButton(
                      multiplier: 1.0,
                      bidIncrement: bidIncrement,
                      currentPrice: currentPrice,
                      isDisabled: isAuctionEnded,
                    ),
                  ),
                  gapW8,
                  Expanded(
                    child: _buildBidMultiplierButton(
                      multiplier: 1.5,
                      bidIncrement: bidIncrement,
                      currentPrice: currentPrice,
                      isDisabled: isAuctionEnded,
                    ),
                  ),
                  gapW8,
                  Expanded(
                    child: _buildBidMultiplierButton(
                      multiplier: 2.0,
                      bidIncrement: bidIncrement,
                      currentPrice: currentPrice,
                      isDisabled: isAuctionEnded,
                    ),
                  ),
                ],
              ),
              gapH16,
            ],

            if (!auctionNotStarted) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '${AppStrings.currency.tr()} ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _customBidController,
                        focusNode: _customBidFocus,
                        enabled: !auctionNotStarted,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'customBidHint'.tr(),
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            // Unselect quick multipliers visually
                            setState(() {
                              _selectedMultiplier = 0.0;
                            });
                          } else {
                            setState(() {
                              _selectedMultiplier = 1.0;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              gapH16,
            ],
            // Main Bid Button - uses selected multiplier or custom proxy bid
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: auctionNotStarted
                    ? null
                    : () {
                        double bidAmount = 0;
                        if (!widget.showOnlyMaxBid && _selectedMultiplier > 0) {
                          bidAmount =
                              currentPrice +
                              (bidIncrement * _selectedMultiplier);
                        } else {
                          final parsed = double.tryParse(
                            _customBidController.text,
                          );
                          if (parsed != null && parsed > currentPrice) {
                            bidAmount = parsed;
                          } else {
                            // Fallback or show error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'يرجى إدخال مبلغ أكبر من المزايدة الحالية',
                                ),
                              ),
                            );
                            return;
                          }
                        }

                        _customBidFocus.unfocus();
                        _customBidController.clear();
                        setState(() {
                          if (currentProductId != null &&
                              _selectedMultiplier == 0.0) {
                            _userMaxBids[currentProductId] = bidAmount;
                          }
                          _selectedMultiplier = 1.0;
                        });
                        widget.onPlaceBid(1, bidAmount, currentProductId);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D4739),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  auctionNotStarted
                      ? AppStrings.willStartSoon.tr()
                      : (!widget.showOnlyMaxBid && _selectedMultiplier > 0
                            ? AppStrings.bidNow.tr()
                            : 'setMaxBid'.tr()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Builder(
              builder: (context) {
                if (currentProductId == null) return const SizedBox.shrink();

                // Check local first (most immediate), then remote server response
                double? displayMaxBid;
                if (_userMaxBids.containsKey(currentProductId)) {
                  displayMaxBid = _userMaxBids[currentProductId];
                } else if (remoteMaxBids.isNotEmpty) {
                  // Find highest max bid for this product globally or by current user
                  final productMaxBids = remoteMaxBids
                      .where((b) => b.productId == currentProductId)
                      .toList();
                  if (productMaxBids.isNotEmpty) {
                    productMaxBids.sort(
                      (a, b) => (b.maxAmount ?? 0).compareTo(a.maxAmount ?? 0),
                    );
                    displayMaxBid = productMaxBids.first.maxAmount?.toDouble();
                  }
                }

                if (displayMaxBid != null) {
                  return Column(
                    children: [
                      gapH8,
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gavel,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${'yourMaxBid'.tr()}: \$${displayMaxBid.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ] else
            _buildResultContainer(currentPrice, orders),
        ],
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
                (o.auctionProductId == currentProductId ||
                    o.productId == currentProductId) &&
                o.auctionId == widget.auction.id,
          )
          .firstOrNull;

      final bool showCheckOrder =
          existingOrder != null &&
          (existingOrder.orderStatus == 'confirmed' ||
              existingOrder.orderStatus == 'pending_approval');

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
                  Text(
                    '${'finalPrice'.tr()}: \$${finalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.green, fontSize: 14),
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
                    auctionTitle: widget.auction.title ?? '',
                    auctionStartDate:
                        widget.auction.startDate ?? DateTime.now(),
                    winnerName: '',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderConfirmationScreen(
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
                Text(
                  '${'finalPrice'.tr()}: \$${finalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
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
                Text(
                  '${'finalPrice'.tr()}: \$${finalPrice.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
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

  Widget _buildBidMultiplierButton({
    required double multiplier,
    required num bidIncrement,
    required num currentPrice,
    required bool isDisabled,
  }) {
    final bool isSelected = _selectedMultiplier == multiplier;
    // Calculate total bid price (current + increment * multiplier)
    final num totalBidPrice = currentPrice + (bidIncrement * multiplier);
    final String label = '\$${totalBidPrice.toStringAsFixed(0)}';

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedMultiplier = multiplier;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D4739) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.shade300
                : (isSelected ? const Color(0xFF2D4739) : Colors.grey.shade400),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDisabled
                  ? Colors.grey
                  : (isSelected ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
