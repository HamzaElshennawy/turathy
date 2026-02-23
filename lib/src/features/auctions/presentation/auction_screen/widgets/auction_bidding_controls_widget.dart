import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/domain/winning_auction_model.dart';
import 'package:turathy/src/features/orders/presentation/order_confirmation_screen.dart';
import 'package:turathy/src/features/orders/presentation/order_details_screen.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';

class AuctionBiddingControlsWidget extends ConsumerStatefulWidget {
  final AuctionModel auction;
  final Function(int qty, num price) onPlaceBid;
  final DateTime? expiryDate;
  final bool isAuctionEnded;
  final bool isOwner;
  final int? winnerId;
  final String? winnerName;
  final num? finalPrice;
  final bool isViewOnly;
  final AuctionProducts? selectedProduct;

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

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void didUpdateWidget(covariant AuctionBiddingControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auction.expiryDate != widget.auction.expiryDate ||
        oldWidget.expiryDate != widget.expiryDate) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    _timer?.cancel();

    final expiry = widget.expiryDate ?? widget.auction.expiryDate;

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

    // bidPrice is the minimum bid increment, not the current price
    num bidIncrement = widget.auction.bidPrice ?? 0;
    // minBidPrice is the opening price (starting price)
    num openingPrice = widget.auction.minBidPrice ?? 0;

    // Find the current product ID to filter bids correctly
    // This prevents using bids from a previous item when joining a running auction
    int? currentProductId = widget.auction.currentProductId;
    if (currentProductId == null &&
        widget.auction.currentProduct != null &&
        widget.auction.auctionProducts != null) {
      final match = widget.auction.auctionProducts!.firstWhere(
        (p) => p.product == widget.auction.currentProduct,
        orElse: () => AuctionProducts(),
      );
      currentProductId = match.id;
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

    if (auctionProduct != null) {
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

    final bool isAuctionEnded =
        _remainingTime == Duration.zero || widget.isAuctionEnded;

    // Check status based on the determine latest bid
    final bool isHighestBidder = latestBid?.userId == CachedVariables.userId;

    // Check if user has participated in the auction
    final bool hasParticipated =
        widget.auction.auctionBids?.any(
          (bid) => bid.userId == CachedVariables.userId,
        ) ??
        false;

    // A user is outbid if they participated but are not the highest bidder
    final bool hasBeenOutbid = hasParticipated && !isHighestBidder;

    final int bidNumber = widget.auction.auctionBids?.length ?? 0;

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
                    'المواجهة رقم: ${bidNumber.toString().padLeft(3, '0')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  gapH4,
                  // Status indicator
                  if (isHighestBidder)
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
                        const Text(
                          'اعلى مزايدة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
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
                        const Text(
                          'هناك مزايدة اعلى منك',
                          style: TextStyle(
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
                    'المزاد الحالي',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '\$${currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
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
                                  '${'finalPrice'.tr()}: \$${wonPrice.toStringAsFixed(0)}',
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
          ] else if (!isAuctionEnded) ...[
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
            // Main Bid Button - uses selected multiplier
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final bidAmount =
                      currentPrice + (bidIncrement * _selectedMultiplier);
                  widget.onPlaceBid(1, bidAmount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D4739),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'زايد الآن',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
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
        final bool userBid =
            widget.auction.auctionBids?.any(
              (bid) => bid.userId == CachedVariables.userId,
            ) ??
            false;

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
    final String label = totalBidPrice.toStringAsFixed(0);

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
