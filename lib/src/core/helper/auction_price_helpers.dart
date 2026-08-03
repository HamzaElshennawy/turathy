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

/// Item Number from API, else [fallbackIndex] (1-based list index).
int displayLotNumber(AuctionProducts product, {required int fallbackIndex}) {
  final lot = product.lotNumber;
  if (lot != null && lot > 0) return lot;
  return fallbackIndex < 1 ? 1 : fallbackIndex;
}

/// Opening floor for live bidding controls (auction-level or selected product).
num openingPriceFromAuction({
  required num? auctionBidPrice,
  AuctionProducts? selectedProduct,
  num? auctionMinBidPriceLegacy,
}) {
  if (selectedProduct != null) {
    final fromProduct = publicStartingPrice(selectedProduct);
    if (fromProduct > 0) return fromProduct;
    // Admin / legacy payloads may still expose reserve; never preferred.
    final legacy = parseMoney(selectedProduct.minBidPrice);
    if (legacy > 0) return legacy;
  }
  final fromAuction = auctionBidPrice ?? 0;
  if (fromAuction > 0) return fromAuction;
  return auctionMinBidPriceLegacy ?? 0;
}
