import 'package:turathy/src/features/auctions/domain/auction_model.dart';

/// Ignore a live-room bid event when it belongs to a different lot
/// than the one currently open for bidding.
bool shouldIgnoreLiveBid({
  required int? eventProductId,
  required int? currentProductId,
}) {
  if (eventProductId == null || currentProductId == null) return false;
  return eventProductId != currentProductId;
}

/// Visible price from a sender-only `bidAccepted` ACK.
num? parseBidAcceptedPrice(Map<String, dynamic> data) {
  for (final raw in [data['visibleBid'], data['currentPrice']]) {
    final parsed = parseOptionalNum(raw);
    if (parsed != null && parsed > 0) return parsed;
  }
  final nested = data['newBid'];
  if (nested is Map) {
    final bid = parseOptionalNum(nested['bid']);
    if (bid != null && bid > 0) return bid;
  }
  return null;
}

num? parseOptionalNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

int? parsePositiveInt(dynamic value) {
  if (value is int && value > 0) return value;
  if (value is num && value > 0) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) return parsed;
  }
  return null;
}

/// Keep REST refreshes from wiping a newer socket price/timer.
void applyHeldLiveFields(
  AuctionModel auction, {
  num? heldPrice,
  DateTime? heldExpiry,
}) {
  if (heldPrice != null) auction.actualPrice = heldPrice;
  if (heldExpiry != null) auction.expiryDate = heldExpiry;
}
