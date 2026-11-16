/// Platform price / lot helpers for Turathy mobile.
///
/// Contract (must match backend + Excel upload):
/// - [AuctionProducts.bidPrice] = public starting / current floor (`starting_price`)
/// - [AuctionProducts.minBidPrice] = private reserve (`reserve_price`) — absent on public API
/// - [AuctionProducts.lotNumber] = Item Number (`lot_number`)
///
/// Bid increments use the server ladder, not a product field.
library;

import 'package:turathy/src/features/auctions/domain/auction_model.dart';

num parseMoney(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

/// Public display / opening floor for a lot (never the reserve).
num publicStartingPrice(AuctionProducts product) =>
    parseMoney(product.bidPrice);

/// List/grid price: highest bid if any, else public starting price.
num displayLotPrice(AuctionProducts product, {num? highestBid}) {
  if (highestBid != null) return highestBid;
  return publicStartingPrice(product);
}

/// The price a lot sheet may show or bid against.
///
/// [openingPrice] is only the floor. A bid already stored on the lot, or the
/// same highest bid the list is showing, replaces it when it is higher.
num highestVisibleBid({
  required num openingPrice,
  num? knownHighest,
  Iterable<num?> amounts = const [],
}) {
  var price = openingPrice;
  if (knownHighest != null && knownHighest > price) price = knownHighest;
  for (final amount in amounts) {
    if (amount != null && amount > price) price = amount;
  }
  return price;
}

/// Bids that belong to the open lot.
///
/// The lot's own history is kept. Auction-level rows are added when they
/// name this lot, or name no lot. A repeated id is kept once.
List<AuctionBid> bidsForSelectedLot({
  List<AuctionBid>? productBids,
  List<AuctionBid>? auctionBids,
  int? productId,
}) {
  final seen = <int>{};
  final merged = <AuctionBid>[];
  void add(AuctionBid bid) {
    final id = bid.id;
    if (id != null && !seen.add(id)) return;
    merged.add(bid);
  }

  for (final bid in productBids ?? const <AuctionBid>[]) {
    add(bid);
  }
  for (final bid in auctionBids ?? const <AuctionBid>[]) {
    if (productId != null &&
        bid.productId != null &&
        bid.productId != productId) {
      continue;
    }
    add(bid);
  }
  return merged;
}

/// Item Number from API, else [fallbackIndex] (1-based list index).
int displayLotNumber(AuctionProducts product, {required int fallbackIndex}) {
  final lot = product.lotNumber;
  if (lot != null && lot > 0) return lot;
  return fallbackIndex < 1 ? 1 : fallbackIndex;
}

/// Opening floor for live bidding controls (auction-level or selected product).
/// Never uses reserve (`minBidPrice`).
num openingPriceFromAuction({
  required num? auctionBidPrice,
  AuctionProducts? selectedProduct,
}) {
  if (selectedProduct != null) {
    final fromProduct = publicStartingPrice(selectedProduct);
    if (fromProduct > 0) return fromProduct;
  }
  return auctionBidPrice ?? 0;
}
