import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_gallery_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_info_table_widget.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

class AuctionItemDetailsWidget extends StatelessWidget {
  final AuctionModel auction;
  final AuctionProducts? activeProduct;
  final bool isAuctionEnded;

  const AuctionItemDetailsWidget({
    Key? key,
    required this.auction,
    required this.activeProduct,
    required this.isAuctionEnded,
  }) : super(key: key);

  bool _isSameProduct(String? p1, String? p2) {
    if (p1 == null || p2 == null) return false;
    return p1.trim().toLowerCase() == p2.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Gallery
        Builder(
          builder: (context) {
            String? statusLabel;
            Color? statusColor;
            final int? currentUserId = CachedVariables.userId;

            // Use local state if ended, otherwise check model
            // Determine status for the ACTIVE product (displayed in big view)
            if (activeProduct != null && activeProduct!.id != null) {
              final bool isCurrentLiveProduct = _isSameProduct(
                activeProduct!.displayName,
                auction.currentProduct,
              );

              // If it's the current live product, check if the AUCTION itself is ended/expired.
              // If auction is live and this is the current product, no special "Sold" badge needed yet (unless expired).

              bool isProductEnded = false;

              if (auction.isPreAuction ||
                  auction.startDate!.isAfter(DateTime.now())) {
                isProductEnded = false;
              } else if (isCurrentLiveProduct) {
                isProductEnded =
                    isAuctionEnded ||
                    auction.isExpired == true ||
                    auction.isCanceled == true;
                if (auction.expiryDate != null &&
                    auction.expiryDate!.isBefore(DateTime.now())) {
                  isProductEnded = true;
                }
              } else {
                final currentIndex = auction.auctionProducts!.indexWhere(
                  (p) =>
                      _isSameProduct(p.displayName, auction.currentProduct) ||
                      p.id == auction.currentProductId,
                );
                final activeIndex = auction.auctionProducts!.indexWhere(
                  (p) => p.id == activeProduct!.id,
                );
                if (currentIndex != -1 &&
                    activeIndex > currentIndex &&
                    !isAuctionEnded &&
                    auction.isExpired != true &&
                    auction.isCanceled != true) {
                  isProductEnded = false;
                } else {
                  isProductEnded = true;
                }
              }

              if (isProductEnded) {
                // Logic to determine Won/Lost/Sold for THIS product
                final productBids =
                    auction.auctionBids
                        ?.where((b) => b.productId == activeProduct!.id)
                        .toList() ??
                    [];

                AuctionBid? highestBid;
                if (productBids.isNotEmpty) {
                  productBids.sort(
                    (a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0),
                  );
                  highestBid = productBids.first;
                }

                if (highestBid != null) {
                  if (highestBid.userId == currentUserId) {
                    statusLabel = AppStrings.youWon.tr();
                    statusColor = Colors.green;
                  } else {
                    // Check if current user bid on this product
                    final didIBid = productBids.any(
                      (b) => b.userId == currentUserId,
                    );
                    if (didIBid) {
                      statusLabel = AppStrings.youLost.tr();
                      statusColor = Colors.red;
                    } else {
                      statusLabel = AppStrings.sold.tr();
                      statusColor = Colors.red;
                    }
                  }
                } else {
                  // No bids — item ended without any bids
                  statusLabel = AppStrings.sold.tr();
                  statusColor = Colors.grey;
                }
              } else {
                if (auction.isPreAuction) {
                  //statusLabel = 'preAuctionPhase'.tr();
                  //statusColor = Colors.blue;
                } else if (!isCurrentLiveProduct) {
                  statusLabel = null;
                } else {
                  statusLabel = AppStrings.live.tr();
                  statusColor = Colors.red;
                }
              }
            }

            final List<String> imagesToShow = [];

            // If we have a specific product active and it has images, show ONLY those
            if (activeProduct?.images != null &&
                activeProduct!.images!.isNotEmpty) {
              imagesToShow.addAll(activeProduct!.images!);
            } else if (activeProduct?.imageUrl != null &&
                activeProduct!.imageUrl!.isNotEmpty) {
              imagesToShow.add(activeProduct!.imageUrl!);
            } else if (auction.imageUrl != null &&
                auction.imageUrl!.isNotEmpty) {
              // Fallback to auction main image if product has no image
              imagesToShow.add(auction.imageUrl!);
            }

            // If no specific product image, we might show nothing or fallback.
            // Let's keep existing fallback behavior for now but EXCLUDE auctionImages if we have product image.

            if (imagesToShow.isEmpty && auction.auctionImages != null) {
              imagesToShow.addAll(auction.auctionImages!);
            }

            return Stack(
              children: [
                AuctionGalleryWidget(images: imagesToShow),
                // SOLD Badge Logic for Main Image
                if (statusLabel != null)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (statusColor ?? Colors.red).withValues(
                          alpha: 0.9,
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        // Info Table
        AuctionInfoTableWidget(auction: auction, currentProduct: activeProduct),
      ],
    );
  }
}
