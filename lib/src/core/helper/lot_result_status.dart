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

/// Whether an `auctionItemEnded` event should play sound, notify, and move
/// the room. A repeated id or a client already sitting on the next lot still
/// records the sale; it must not run those side effects again.
class EndedLotApply {
  const EndedLotApply({required this.sold, required this.runSideEffects});

  /// Server `isSold` only. Null means the payload did not decide, so the
  /// room must not write «لم يبع» or clear a sale already recorded.
  final bool? sold;
  final bool runSideEffects;
}

EndedLotApply endedLotApply({
  required int? endedProductId,
  required int? lastEndedProductId,
  required int? nextItemId,
  required int? currentProductId,
  required bool? eventIsSold,
  required bool hasWinner,
}) {
  final duplicate =
      endedProductId != null && endedProductId == lastEndedProductId;
  final alreadyOnNext = nextItemId != null &&
      nextItemId == currentProductId &&
      endedProductId != currentProductId;
  // A winner object without isSold is not a sale decision.
  final winnerWithoutFlag = hasWinner && eventIsSold == null;
  return EndedLotApply(
    sold: winnerWithoutFlag ? null : eventIsSold,
    runSideEffects: !duplicate && !alreadyOnNext,
  );
}

/// Sale that is safe to paint on a lot which is no longer open.
///
/// Null means neither the live event nor the product row has an explicit
/// decision yet. A missing flag must not become «لم يبع».
bool? explicitLotSale({
  bool? eventIsSold,
  bool? productIsSold,
  bool? productExpired,
}) {
  if (productIsSold == true) return true;
  if (eventIsSold != null) return eventIsSold;
  if (productExpired == true) return false;
  return null;
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

/// A product the API already marked sold stays sold.
/// A stale session `false` must not hide that flag.
bool badgeLotWasSold({
  bool? productIsSold,
  bool? eventIsSold,
  bool hasWinner = false,
}) {
  if (productIsSold == true) return true;
  return lotWasSold(
    productIsSold: productIsSold,
    eventIsSold: eventIsSold,
    hasWinner: hasWinner,
  );
}

/// «لم يُبع» needs a server close. Sitting before the live lot is not enough.
bool lotExplicitlyUnsold({
  bool? productIsExpired,
  bool? eventIsSold,
  bool auctionClosed = false,
}) {
  if (eventIsSold == false) return true;
  if (productIsExpired == true) return true;
  return auctionClosed;
}

/// Sold only when [isSold]. Unsold only when [explicitlyUnsold].
/// Otherwise the lot has no result badge yet.
LotResultKind settledLotBadge({
  required bool isSold,
  required bool explicitlyUnsold,
  int? currentUserId,
  int? winnerUserId,
  required bool userParticipated,
}) {
  if (!isSold && !explicitlyUnsold) return LotResultKind.none;
  return resolveLotResult(
    isEnded: true,
    isLive: false,
    isSold: isSold,
    currentUserId: currentUserId,
    winnerUserId: winnerUserId,
    userParticipated: userParticipated,
  );
}

/// Stamp the lot that just closed, never the lot that is about to open.
/// When the pointer already moved, the previous id is the one before [nextItemId].
int? endedLotIdToStamp({
  required int? eventEndedProductId,
  required int? currentProductId,
  required int? nextItemId,
  required List<int?> productIdsInOrder,
}) {
  if (eventEndedProductId != null) return eventEndedProductId;
  if (nextItemId != null && currentProductId == nextItemId) {
    final nextIndex = productIdsInOrder.indexOf(nextItemId);
    if (nextIndex > 0) return productIdsInOrder[nextIndex - 1];
  }
  return currentProductId;
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
/// Never paint the previous lot's result on the next live item, and never
/// while the selected lot is still open for bids (local timer at 0 is not
/// a sale decision).
LotResultKind overlayLotResult({
  required LotResultKind kind,
  required int? resultProductId,
  required int? selectedProductId,
  required int? currentLiveProductId,
  required bool selectedLotClosedByServer,
}) {
  if (kind == LotResultKind.none) return LotResultKind.none;

  final selectedIsCurrentLive = selectedProductId != null &&
      currentLiveProductId != null &&
      selectedProductId == currentLiveProductId;
  final viewingOpenLiveLot = !selectedLotClosedByServer &&
      (selectedIsCurrentLive ||
          currentLiveProductId == null ||
          selectedProductId == null);
  if (viewingOpenLiveLot) {
    return LotResultKind.none;
  }

  if (resultProductId != null &&
      selectedProductId != null &&
      resultProductId != selectedProductId) {
    return LotResultKind.none;
  }

  if (kind == LotResultKind.unsold && !selectedLotClosedByServer) {
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

class LotBidRow {
  const LotBidRow({this.id, this.productId, this.userId, this.amount});

  final int? id;
  final int? productId;
  final int? userId;
  final num? amount;
}

class LotPriceLead {
  const LotPriceLead({this.userId, this.amount});

  final int? userId;
  final num? amount;
}

/// Highest bid on one lot. Rows from the live product list and the
/// auction list are combined; a later higher amount wins.
LotPriceLead leadingLotBid(Iterable<LotBidRow> rows, int productId) {
  final bestById = <int, LotBidRow>{};
  final withoutId = <LotBidRow>[];
  for (final row in rows) {
    if (row.productId != null && row.productId != productId) continue;
    final id = row.id;
    if (id == null) {
      withoutId.add(row);
      continue;
    }
    final previous = bestById[id];
    if (previous == null || (row.amount ?? 0) >= (previous.amount ?? 0)) {
      bestById[id] = row;
    }
  }
  LotBidRow? best;
  for (final row in [...bestById.values, ...withoutId]) {
    if (best == null || (row.amount ?? 0) > (best.amount ?? 0)) {
      best = row;
    }
  }
  return LotPriceLead(userId: best?.userId, amount: best?.amount);
}

/// The large price is this lot's own price. The auction hammer is shown
/// only on the lot that just closed.
num headerPriceForSelectedLot({
  required num lotPrice,
  required bool auctionEnded,
  required num? auctionFinalPrice,
  required int? selectedLotId,
  required int? endedLotId,
}) {
  if (auctionEnded &&
      auctionFinalPrice != null &&
      selectedLotId != null &&
      endedLotId != null &&
      selectedLotId == endedLotId) {
    return auctionFinalPrice;
  }
  return lotPrice;
}

/// After the auction closes, every selected lot is view-only.
/// A missing live pointer must not keep the last winner on the other lots.
bool selectedLotIsViewOnly({
  required bool isPreAuction,
  required bool hasSelectedProduct,
  required bool auctionEnded,
  required bool selectedIsCurrentLive,
}) {
  if (isPreAuction || !hasSelectedProduct) return false;
  return auctionEnded || !selectedIsCurrentLive;
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
