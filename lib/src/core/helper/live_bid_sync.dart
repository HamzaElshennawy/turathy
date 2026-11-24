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

/// One painted lot: price, confrontation count, winner, and the caller's ceiling.
/// Both `bidAccepted` and `newBid` write this. A later event replaces it.
class LiveLotPaint {
  const LiveLotPaint({
    this.productId,
    this.price,
    this.confrontation = 0,
    this.leaderUserId,
    this.bidId,
    this.ownMax,
    this.suppressOwnMax = false,
    this.userParticipated = false,
  });

  final int? productId;
  final num? price;
  final int confrontation;
  final int? leaderUserId;
  final int? bidId;
  final num? ownMax;
  final bool suppressOwnMax;
  final bool userParticipated;
}

/// What one socket event wants to paint. [bidId] is `newBid.id`.
class LiveLotPaintInput {
  const LiveLotPaintInput({
    required this.fromAccepted,
    this.productId,
    this.bidId,
    this.leaderUserId,
    this.price,
    this.confrontation = 0,
    this.explicitOutbid = false,
    this.submittedAmount,
    this.sessionUserId,
    this.participantIds = const [],
  });

  final bool fromAccepted;
  final int? productId;
  final int? bidId;
  final int? leaderUserId;
  final num? price;
  final int confrontation;
  final bool explicitOutbid;
  final num? submittedAmount;
  final int? sessionUserId;
  final List<int> participantIds;
}

enum LiveLotPaintEffect { ignored, ceilingOnly, painted }

class LiveLotPaintResult {
  const LiveLotPaintResult({required this.paint, required this.effect});

  final LiveLotPaint paint;
  final LiveLotPaintEffect effect;
}

class _CeilingPaint {
  const _CeilingPaint({required this.ownMax, required this.suppress});

  final num? ownMax;
  final bool suppress;
}

/// A winning `bidAccepted` restores the green line. Any other leader hides it,
/// including a tie where the visible price equals the saved ceiling.
_CeilingPaint _resolveCeiling({
  required num? ownMax,
  required bool suppress,
  required num? price,
  required int? leaderUserId,
  required LiveLotPaintInput incoming,
}) {
  var nextMax = ownMax;
  var nextSuppress = suppress;
  final sessionUserId = incoming.sessionUserId;
  final userWon = incoming.fromAccepted &&
      !incoming.explicitOutbid &&
      (incoming.leaderUserId == null ||
          sessionUserId == null ||
          incoming.leaderUserId == sessionUserId);
  if (userWon &&
      incoming.submittedAmount != null &&
      incoming.submittedAmount! > 0) {
    nextMax = incoming.submittedAmount;
    nextSuppress = false;
  }
  final otherLeads = leaderUserId != null &&
      sessionUserId != null &&
      leaderUserId != sessionUserId;
  if (otherLeads || incoming.explicitOutbid) {
    return const _CeilingPaint(ownMax: null, suppress: true);
  }
  if (price != null && nextMax != null && price > nextMax) {
    return const _CeilingPaint(ownMax: null, suppress: true);
  }
  return _CeilingPaint(ownMax: nextMax, suppress: nextSuppress);
}

LiveLotPaint _ceilingOnly(LiveLotPaint current, LiveLotPaintInput incoming) {
  final ceiling = _resolveCeiling(
    ownMax: current.ownMax,
    suppress: current.suppressOwnMax,
    price: current.price,
    leaderUserId: current.leaderUserId,
    incoming: incoming,
  );
  return LiveLotPaint(
    productId: current.productId,
    price: current.price,
    confrontation: current.confrontation,
    leaderUserId: current.leaderUserId,
    bidId: current.bidId,
    ownMax: ceiling.ownMax,
    suppressOwnMax: ceiling.suppress,
    userParticipated: current.userParticipated || incoming.fromAccepted,
  );
}

/// Applies one live event. An older [LiveLotPaintInput.bidId] is ignored.
/// The same id may refresh the ceiling and must not move the winner.
/// Without an id, the event applies only when the confrontation count grows.
LiveLotPaintResult applyLiveLotPaint({
  required LiveLotPaint? current,
  required LiveLotPaintInput incoming,
}) {
  final baseline = current ?? const LiveLotPaint();
  if (incoming.productId != null &&
      baseline.productId != null &&
      incoming.productId != baseline.productId) {
    return LiveLotPaintResult(
      paint: baseline,
      effect: LiveLotPaintEffect.ignored,
    );
  }
  final incomingId = incoming.bidId;
  final appliedId = baseline.bidId;
  if (incomingId != null && appliedId != null && incomingId < appliedId) {
    return LiveLotPaintResult(
      paint: baseline,
      effect: LiveLotPaintEffect.ignored,
    );
  }
  if (incomingId != null && appliedId != null && incomingId == appliedId) {
    return LiveLotPaintResult(
      paint: _ceilingOnly(baseline, incoming),
      effect: LiveLotPaintEffect.ceilingOnly,
    );
  }
  if (incomingId == null && incoming.confrontation <= baseline.confrontation) {
    return LiveLotPaintResult(
      paint: baseline,
      effect: LiveLotPaintEffect.ignored,
    );
  }

  final sessionUserId = incoming.sessionUserId;
  final participated = baseline.userParticipated ||
      incoming.fromAccepted ||
      (sessionUserId != null &&
          (incoming.leaderUserId == sessionUserId ||
              incoming.participantIds.contains(sessionUserId)));
  final price = incoming.price ?? baseline.price;
  final leaderUserId = incoming.leaderUserId ?? baseline.leaderUserId;
  final ceiling = _resolveCeiling(
    ownMax: baseline.ownMax,
    suppress: baseline.suppressOwnMax,
    price: price,
    leaderUserId: leaderUserId,
    incoming: incoming,
  );
  return LiveLotPaintResult(
    paint: LiveLotPaint(
      productId: incoming.productId ?? baseline.productId,
      price: price,
      confrontation: incoming.confrontation > 0
          ? incoming.confrontation
          : baseline.confrontation,
      leaderUserId: leaderUserId,
      bidId: incomingId ?? appliedId,
      ownMax: ceiling.ownMax,
      suppressOwnMax: ceiling.suppress,
      userParticipated: participated,
    ),
    effect: LiveLotPaintEffect.painted,
  );
}

/// Green «أعلى مزايدة» follows the server winner, not an equal amount.
/// An explicit outbid stays outbid even when both sides show the same price.
bool sessionUserLeadsLot({
  required int? sessionUserId,
  required int? leaderUserId,
  required bool ackOutbid,
  required bool amountSaysLeader,
}) {
  if (sessionUserId == null) return false;
  if (ackOutbid) return false;
  if (leaderUserId != null) return leaderUserId == sessionUserId;
  return amountSaysLeader;
}

/// Sender lost the proxy war in the same accepted bid.
class BidAcceptDecision {
  const BidAcceptDecision({
    required this.outbid,
    this.visibleBid,
    this.submittedAmount,
    this.leaderUserId,
  });

  final bool outbid;
  final num? visibleBid;
  final num? submittedAmount;
  final int? leaderUserId;
}

BidAcceptDecision decideBidAccept(
  Map<String, dynamic> data, {
  int? sessionUserId,
}) {
  final visibleBid = parseBidAcceptedPrice(data);
  final submittedAmount = parseOptionalNum(data['submittedAmount']);
  final nested = data['newBid'];
  final leaderUserId = nested is Map
      ? parsePositiveInt(nested['user_id'] ?? nested['userId'])
      : null;
  final explicit = data['outbid'] == true;
  return BidAcceptDecision(
    outbid: explicit,
    visibleBid: visibleBid,
    submittedAmount: submittedAmount,
    leaderUserId: leaderUserId,
  );
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
bool shouldEmitLiveBid({required bool pendingForProduct}) => !pendingForProduct;

num heldPriceForNextLot(num nextOpeningBidPrice) => nextOpeningBidPrice;
