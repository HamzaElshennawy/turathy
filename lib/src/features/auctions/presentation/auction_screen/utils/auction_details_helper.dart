import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/lot_result_status.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

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
    bool? isSoldOverride,
    int? winnerUserIdOverride,
    bool? userParticipatedOverride,
  }) {
    String? statusLabel;
    Color? statusColor;
    final int? currentUserId = CachedVariables.userId;

    if (activeProduct != null && activeProduct.id != null) {
      final bool isCurrentLiveProduct = auction.currentProductId != null
          ? activeProduct.id == auction.currentProductId
          : _isSameProduct(
              activeProduct.displayName,
              auction.currentProduct,
            );

      bool isProductEnded = false;

      if (auction.isPreAuction ||
          (auction.startDate != null && auction.startDate!.isAfter(DateTime.now()))) {
        isProductEnded = false;
      } else if (isCurrentLiveProduct) {
        isProductEnded = isCurrentLiveLotClosedByServer(
          isAuctionEnded: isAuctionEnded,
          auctionExpired: auction.isExpired,
          auctionCanceled: auction.isCanceled,
          productSold: activeProduct.isSold,
          productExpired: activeProduct.isExpired,
        );
      } else {
        final currentIndex = auction.auctionProducts!.indexWhere(
          (p) =>
              auction.currentProductId != null
                  ? p.id == auction.currentProductId
                  : _isSameProduct(p.displayName, auction.currentProduct) ||
                      p.id == auction.currentProductId,
        );
        final activeIndex = auction.auctionProducts!.indexWhere(
          (p) => p.id == activeProduct.id,
        );
        if (currentIndex == -1) {
          // No current-lot pointer yet — do not stamp every lot as unsold.
          isProductEnded = isAuctionEnded ||
              auction.isExpired == true ||
              auction.isCanceled == true;
        } else if (currentIndex != -1 &&
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

        final isSold = lotWasSold(
          productIsSold: activeProduct.isSold,
          eventIsSold: isSoldOverride,
          hasWinner: winnerUserIdOverride != null,
        );

        int? winnerId = winnerUserIdOverride;
        if (winnerId == null && isSold) {
          winnerId = highestBid?.userId;
        }

        final didIBid = userParticipatedOverride ??
            productBids.any((b) => b.userId == currentUserId);

        final kind = resolveLotResult(
          isEnded: true,
          isLive: false,
          isSold: isSold,
          currentUserId: currentUserId,
          winnerUserId: winnerId,
          userParticipated: didIBid,
        );
        final visible = visibleLotResult(
          kind,
          auctionFullyEnded: auctionIsFullyEnded(
            isAuctionEnded: isAuctionEnded,
            isExpired: auction.isExpired,
            isCanceled: auction.isCanceled,
          ),
        );
        if (visible == LotResultKind.none) {
          statusLabel = null;
          statusColor = null;
        } else {
          statusLabel = lotResultStringKey(visible).tr();
          statusColor = lotResultColor(visible);
        }
      } else {
        if (auction.isPreAuction) {
          //statusLabel = 'preAuctionPhase'.tr();
          //statusColor = Colors.blue;
        } else if (!isCurrentLiveProduct) {
          statusLabel = null;
        } else {
          final kind = LotResultKind.live;
          statusLabel = lotResultStringKey(kind).tr();
          statusColor = lotResultColor(kind);
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
