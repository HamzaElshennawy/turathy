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
      return Colors.red;
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
