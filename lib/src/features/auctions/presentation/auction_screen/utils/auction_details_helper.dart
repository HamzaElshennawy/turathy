import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

class AuctionStatusBadge {
  final String? label;
  final Color? color;

  AuctionStatusBadge({this.label, this.color});
}

class AuctionDetailsHelper {
  static bool _isSameProduct(String? p1, String? p2) {
    if (p1 == null || p2 == null) return false;
    return p1.trim().toLowerCase() == p2.trim().toLowerCase();
  }

  static AuctionStatusBadge getStatusBadge({
    required AuctionModel auction,
    required AuctionProducts? activeProduct,
    required bool isAuctionEnded,
  }) {
    String? statusLabel;
    Color? statusColor;
    final int? currentUserId = CachedVariables.userId;

    if (activeProduct != null && activeProduct.id != null) {
      final bool isCurrentLiveProduct = _isSameProduct(
        activeProduct.displayName,
        auction.currentProduct,
      );

      bool isProductEnded = false;

      if (auction.isPreAuction ||
          (auction.startDate != null && auction.startDate!.isAfter(DateTime.now()))) {
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
          (p) => p.id == activeProduct.id,
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
        final productBids =
            auction.auctionBids
                ?.where((b) => b.productId == activeProduct.id)
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

    return AuctionStatusBadge(label: statusLabel, color: statusColor);
  }

  static List<String> getImagesToShow(AuctionModel auction, AuctionProducts? activeProduct) {
    final List<String> imagesToShow = [];
    if (activeProduct?.images != null && activeProduct!.images!.isNotEmpty) {
      imagesToShow.addAll(activeProduct.images!);
    } else if (activeProduct?.imageUrl != null && activeProduct!.imageUrl!.isNotEmpty) {
      imagesToShow.add(activeProduct.imageUrl!);
    } else if (auction.imageUrl != null && auction.imageUrl!.isNotEmpty) {
      imagesToShow.add(auction.imageUrl!);
    }
    if (imagesToShow.isEmpty && auction.auctionImages != null) {
      imagesToShow.addAll(auction.auctionImages!);
    }
    return imagesToShow;
  }
}
