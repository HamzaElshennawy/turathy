/// Lot-end UI contract for Turathy mobile.
///
/// A lot is sold only when the server sets [isSold] (top bid met reserve).
/// Bids on an ended lot never imply a sale — that was the «تم البيع» bug.
library;

import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

enum LotResultKind {
  none,
  live,
  youWon,
  youLost,
  sold,
  unsold,
}

/// Resolves sale from explicit flags. [hasWinner] is a fallback for
/// `auctionItemEnded` payloads that currently omit [eventIsSold] and only
/// attach a winner when the lot actually sold.
bool lotWasSold({
  bool? productIsSold,
  bool? eventIsSold,
  bool hasWinner = false,
}) {
  if (eventIsSold != null) return eventIsSold;
  if (productIsSold != null) return productIsSold;
  return hasWinner;
}

/// Outcome for badges / the non-blocking end-of-lot banner.
///
/// [isEnded] = this lot's timer is over (or it is a past lot).
/// [isLive] = this lot is the current live item.
/// Never returns youWon / youLost / sold unless [isSold] is true.
LotResultKind resolveLotResult({
  required bool isEnded,
  required bool isLive,
  required bool isSold,
  int? currentUserId,
  int? winnerUserId,
  required bool userParticipated,
}) {
  if (!isEnded) {
    return isLive ? LotResultKind.live : LotResultKind.none;
  }
  if (!isSold) return LotResultKind.unsold;
  if (currentUserId != null &&
      winnerUserId != null &&
      currentUserId == winnerUserId) {
    return LotResultKind.youWon;
  }
  if (userParticipated) return LotResultKind.youLost;
  return LotResultKind.sold;
}

/// Whole-auction close flags only — never a lot timer hitting zero.
bool auctionIsFullyEnded({
  required bool isAuctionEnded,
  bool? isExpired,
  bool? isCanceled,
}) {
  return isAuctionEnded || isExpired == true || isCanceled == true;
}

/// Show «لم تُبع» as soon as this lot has ended during a live auction.
/// Hide it only while the lot is still the open live item on the server
/// (local timer at 0 must not stamp unsold).
LotResultKind visibleLotResult(
  LotResultKind kind, {
  required bool thisLotHasEnded,
}) {
  if (kind == LotResultKind.unsold && !thisLotHasEnded) {
    return LotResultKind.none;
  }
  return kind;
}

/// Overlay banner for a lot-end result (dismissible «لم تُبع» / sold).
///
/// Never paint the previous lot's unsold state on the next live item, and
/// never while that item is still open for bids (timer at 0 is not enough).
LotResultKind overlayLotResult({
  required LotResultKind kind,
  required int? resultProductId,
  required int? selectedProductId,
  required int? currentLiveProductId,
  required bool selectedLotClosedByServer,
}) {
  if (kind == LotResultKind.none) return LotResultKind.none;

  if (resultProductId != null &&
      selectedProductId != null &&
      resultProductId != selectedProductId) {
    return LotResultKind.none;
  }

  if (kind != LotResultKind.unsold) return kind;

  final selectedIsCurrentLive = selectedProductId != null &&
      currentLiveProductId != null &&
      selectedProductId == currentLiveProductId;
  if (selectedIsCurrentLive && !selectedLotClosedByServer) {
    return LotResultKind.none;
  }
  if (!selectedLotClosedByServer && currentLiveProductId == null) {
    return LotResultKind.none;
  }
  return kind;
}

String lotResultStringKey(LotResultKind kind) {
  switch (kind) {
    case LotResultKind.none:
      return '';
    case LotResultKind.live:
      return AppStrings.live;
    case LotResultKind.youWon:
      return AppStrings.youWon;
    case LotResultKind.youLost:
      return AppStrings.youLost;
    case LotResultKind.sold:
      return AppStrings.sold;
    case LotResultKind.unsold:
      return AppStrings.unsold;
  }
}

Color lotResultColor(LotResultKind kind) {
  switch (kind) {
    case LotResultKind.none:
      return Colors.transparent;
    case LotResultKind.live:
      return Colors.red;
    case LotResultKind.youWon:
      return Colors.green;
    case LotResultKind.youLost:
      return const Color(0xFF8A6A32);
    case LotResultKind.sold:
      return Colors.grey;
    case LotResultKind.unsold:
      return Colors.blueGrey;
  }
}

IconData lotResultIcon(LotResultKind kind) {
  switch (kind) {
    case LotResultKind.none:
      return Icons.info_outline;
    case LotResultKind.live:
      return Icons.sensors;
    case LotResultKind.youWon:
      return Icons.emoji_events;
    case LotResultKind.youLost:
      return Icons.close;
    case LotResultKind.sold:
      return Icons.gavel;
    case LotResultKind.unsold:
      return Icons.remove_circle_outline;
  }
}

bool _sameLotName(String? a, String? b) {
  if (a == null || b == null) return false;
  return a.trim().toLowerCase() == b.trim().toLowerCase();
}

/// True when [productId]/[productName] is the lot currently open for bids.
///
/// If the server has not published a current-lot pointer, treat the visible
/// lot as live so we do not lock every thumbnail behind «لم تُبع».
bool isCurrentLiveLot({
  required int? productId,
  required String? productName,
  required int? currentProductId,
  required String? currentProductName,
}) {
  if (productId != null && currentProductId != null) {
    return productId == currentProductId;
  }
  if (_sameLotName(productName, currentProductName)) return true;
  final hasPointer = currentProductId != null ||
      (currentProductName != null && currentProductName.trim().isNotEmpty);
  return !hasPointer;
}

bool isUpcomingLiveLot({
  required List<int?> productIdsInOrder,
  required int? selectedProductId,
  required int? currentProductId,
}) {
  if (selectedProductId == null || currentProductId == null) return false;
  final selectedIndex = productIdsInOrder.indexOf(selectedProductId);
  final currentIndex = productIdsInOrder.indexOf(currentProductId);
  return selectedIndex >= 0 && currentIndex >= 0 && selectedIndex > currentIndex;
}

/// Close the current live lot only from server flags — never from the
/// device clock hitting [expiryDate]. That race showed «لم تُبع» and hid
/// سوم / swipe-to-bid while the worker still had the lot open.
bool isCurrentLiveLotClosedByServer({
  required bool isAuctionEnded,
  bool? auctionExpired,
  bool? auctionCanceled,
  bool? productSold,
  bool? productExpired,
}) {
  return isAuctionEnded ||
      auctionExpired == true ||
      auctionCanceled == true ||
      productSold == true ||
      productExpired == true;
}
