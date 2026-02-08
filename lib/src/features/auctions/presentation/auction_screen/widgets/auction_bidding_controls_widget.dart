import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';

class AuctionBiddingControlsWidget extends ConsumerStatefulWidget {
  final AuctionModel auction;
  final Function(int qty, num price) onPlaceBid;

  const AuctionBiddingControlsWidget({
    super.key,
    required this.auction,
    required this.onPlaceBid,
  });

  @override
  ConsumerState<AuctionBiddingControlsWidget> createState() =>
      _AuctionBiddingControlsWidgetState();
}

class _AuctionBiddingControlsWidgetState
    extends ConsumerState<AuctionBiddingControlsWidget> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void didUpdateWidget(covariant AuctionBiddingControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auction.expiryDate != widget.auction.expiryDate) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    _timer?.cancel();

    if (widget.auction.expiryDate != null) {
      final expiryDateTime = DateTime.tryParse(widget.auction.expiryDate!);
      if (expiryDateTime != null) {
        _updateRemainingTime(expiryDateTime);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateRemainingTime(expiryDateTime);
        });
      }
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

    num currentPrice = widget.auction.bidPrice ?? 0;
    num minBid = widget.auction.minBidPrice ?? 0;

    if (auctionProduct != null) {
      currentPrice = auctionProduct.bidPrice;
      minBid = auctionProduct.minBidPrice;
    }

    final bool isAuctionEnded = _remainingTime == Duration.zero;
    final bool isHighestBidder = lastBid?.user?.id == CachedVariables.userId;
    final bool hasBeenOutbid = lastBid != null && !isHighestBidder;
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

          // Timer pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _formatDuration(_remainingTime),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isAuctionEnded ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ),
          gapH16,

          // Quick Bid Buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickBidButton(
                  context,
                  5,
                  currentPrice,
                  isAuctionEnded,
                ),
              ),
              gapW8,
              Expanded(
                child: _buildQuickBidButton(
                  context,
                  10,
                  currentPrice,
                  isAuctionEnded,
                ),
              ),
              gapW8,
              Expanded(
                child: _buildQuickBidButton(
                  context,
                  20,
                  currentPrice,
                  isAuctionEnded,
                ),
              ),
            ],
          ),
          gapH16,

          // Main Bid Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isAuctionEnded
                  ? null
                  : () {
                      widget.onPlaceBid(1, currentPrice + minBid);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuctionEnded
                    ? Colors.grey
                    : const Color(0xFF2D4739),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                isAuctionEnded ? AppStrings.auctionEnded.tr() : 'زايد الآن',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBidButton(
    BuildContext context,
    int amount,
    num currentPrice,
    bool isDisabled,
  ) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              widget.onPlaceBid(1, currentPrice + amount);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '\$$amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDisabled ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
