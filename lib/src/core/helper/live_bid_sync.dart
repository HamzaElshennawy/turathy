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
  if (heldPrice != null) auction.liveCurrentPrice = heldPrice;
  if (heldExpiry != null) auction.expiryDate = heldExpiry;
}

int? parseBidAcceptedAuctionId(Map<String, dynamic> data) {
  final nested = data['newBid'];
  return parsePositiveInt(
    data['auctionId'] ??
        data['auction_id'] ??
        (nested is Map ? nested['auctionId'] ?? nested['auction_id'] : null),
  );
}

int? parseBidAcceptedProductId(Map<String, dynamic> data) {
  final nested = data['newBid'];
  return parsePositiveInt(
    data['productId'] ??
        data['product_id'] ??
        (nested is Map ? nested['productId'] ?? nested['product_id'] : null),
  );
}

String? parseClientBidId(Map<String, dynamic> data) {
  final raw = data['clientBidId'] ?? data['client_bid_id'];
  if (raw == null) return null;
  final value = raw.toString().trim();
  return value.isEmpty ? null : value;
}

class PendingClientBid {
  const PendingClientBid({
    required this.clientBidId,
    required this.auctionId,
    required this.productId,
    required this.amount,
  });

  final String clientBidId;
  final int auctionId;
  final int productId;
  final num amount;
}

/// Fail closed: auction + product must be present and match.
bool matchesPendingBidAck({
  required Map<String, dynamic> data,
  required PendingClientBid pending,
}) {
  final auctionId = parseBidAcceptedAuctionId(data);
  final productId = parseBidAcceptedProductId(data);
  if (auctionId == null || productId == null) return false;
  if (auctionId != pending.auctionId || productId != pending.productId) {
    return false;
  }
  final clientBidId = parseClientBidId(data);
  if (clientBidId != null && clientBidId != pending.clientBidId) return false;
  final submitted = parseOptionalNum(data['submittedAmount']);
  if (submitted != null && submitted != pending.amount) return false;
  return true;
}

/// On `auctionItemEnded` + nextItem, replace the previous lot hammer
/// with the new lot opening (`bidPrice`) so a rebuild cannot flash it.
num heldPriceForNextLot(num nextOpeningBidPrice) => nextOpeningBidPrice;
