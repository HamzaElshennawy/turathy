import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/sign_in_screen.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';

import '../../features/auctions/domain/auction_model.dart';
import '../../features/auctions/presentation/auction_screen/auction_screen.dart';
import '../constants/app_functions/app_functions.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings/app_strings.dart';

class AuctionCard extends ConsumerStatefulWidget {
  final AuctionModel auction;
  final String? heroTag;

  const AuctionCard({super.key, required this.auction, this.heroTag});

  @override
  ConsumerState<AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends ConsumerState<AuctionCard> {
  Timer? _timer;
  Duration _remainingTimeForLive = Duration.zero;
  Duration _remainingTimeForPreAuction = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    if (widget.auction.liveStartDate != null) {
      final liveStartDate = widget.auction.liveStartDate!;
      final now = DateTime.now();
      if (liveStartDate.isAfter(now)) {
        setState(() {
          _remainingTimeForLive = liveStartDate.difference(now);
        });
      } else {
        setState(() {
          _remainingTimeForLive = Duration.zero;
        });
      }
    }
    if (widget.auction.startDate != null) {
      final startDate = widget.auction.startDate!;
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        setState(() {
          _remainingTimeForPreAuction = startDate.difference(now);
        });
      } else {
        setState(() {
          _remainingTimeForPreAuction = Duration.zero;
        });
      }
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
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesControllerProvider);
    final isLiked = favoritesState.maybeWhen(
      data: (state) => state.likedAuctionIds.contains(widget.auction.id),
      orElse: () => false,
    );
    final bool isEnded =
        //_remainingTimeForLive == Duration.zero ||
        widget.auction.isExpired == true
    //||
    //widget.product.isCanceled == true ||
    //(widget.product.liveStartDate != null &&
    //    widget.product.liveStartDate!.isBefore(DateTime.now()))
    //    ||
    //_remainingTimeForPreAuction == Duration.zero
    ;

    String? statusLabel;
    Color? statusColor;

    if (isEnded) {
      statusLabel = AppStrings.auctionEnded.tr();
      statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionScreen(widget.auction),
            ),
          );
        },
        onLongPress: () {
          AppFunctions.showImageDialog(
            context: context,
            imageUrl: widget.auction.imageUrl ?? '',
            id: widget.auction.id ?? 0,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Image Section with Heart Icon
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: widget.heroTag ?? widget.auction.id ?? 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: widget.auction.imageUrl ?? '',
                        memCacheHeight: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) => Center(
                              child: CircularProgressIndicator(
                                value: downloadProgress.progress,
                              ),
                            ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        ),
                      ),
                    ),
                  ),
                  // Heart Icon (Favorite)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: InkWell(
                      onTap: () {
                        final user = ref.read(authControllerProvider).value;
                        if (user == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInScreen(),
                            ),
                          );
                          return;
                        }
                        ref
                            .read(favoritesControllerProvider.notifier)
                            .toggleLikeAuction(widget.auction);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  if (statusLabel != null)
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      start: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor ?? Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.auction.localizedTitle(
                        context.locale.languageCode,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    gapH4,
                    // Description
                    Text(
                      widget.auction.localizedDescription(
                        context.locale.languageCode,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    // Price and Time Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        //Text(
                        //  '${widget.product.minBidPrice ?? 0} ${AppStrings.currency.tr()}',
                        //  style: const TextStyle(
                        //    fontSize: 18,
                        //    fontWeight: FontWeight.bold,
                        //    color: Colors.black87,
                        //  ),
                        //),
                        // Remaining Time
                        // Time Display
                        if (widget.auction.liveStartDate != null &&
                            widget.auction.startDate != null)
                          Builder(
                            builder: (context) {
                              final now = DateTime.now();
                              final startDate = widget.auction.startDate!;
                              final expiryDate = widget.auction.expiryDate!;

                              if (startDate.isAfter(now)) {
                                // Future Auction
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.auction.liveStartDate !=
                                        null) ...[
                                      Text(
                                        '${'preAuctionStartsAt'.tr()}: ${DateFormat('MMM d, h:mm a').format(startDate)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                      Text(
                                        '${'liveStartsAt'.tr()}: ${DateFormat('MMM d, h:mm a').format(widget.auction.liveStartDate!)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        '${AppStrings.startedAt.tr()}: ${DateFormat('MMM d, h:mm a').format(startDate)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                      //Text(
                                      //  '${AppStrings.endedAt.tr()}: ${DateFormat('MMM d, h:mm a').format(expiryDate)}',
                                      //  style: const TextStyle(
                                      //    fontSize: 12,
                                      //    fontWeight: FontWeight.w500,
                                      //    color: Colors.black54,
                                      //  ),
                                      //),
                                    ],
                                  ],
                                );
                              } else if (expiryDate.isBefore(now)) {
                                // Ended Auction
                                return Text(
                                  '${AppStrings.endedOn.tr()}: ${DateFormat('MMM d, h:mm a').format(expiryDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                );
                              } else {
                                // Live Auction
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _remainingTimeForPreAuction > Duration.zero
                                        ? Text(
                                            '${AppStrings.remainingTime.tr()} ${AppStrings.untilPreAuction.tr()}: ${_formatDuration(_remainingTimeForPreAuction)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(
                                                0xFFD32F2F,
                                              ), // Red color
                                            ),
                                          )
                                        : Text(
                                            AppStrings.preAuctionStarted.tr(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green, // Red color
                                            ),
                                          ),
                                    gapH4,
                                    Text(
                                      '${AppStrings.remainingTime.tr()} ${AppStrings.untilLive.tr()}: ${_formatDuration(_remainingTimeForLive)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFD32F2F), // Red color
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                      ],
                    ),
                    gapH8,
                    // Bid Now Button
                    if (!isEnded)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AuctionScreen(widget.auction),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF1B5E20,
                            ), // Dark green
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            AppStrings.bidNow.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
