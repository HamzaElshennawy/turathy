/// Bid increment ladder for Turathy mobile (must match server thresholds).
library;

/// Auction 4 (id 125) lot 12. Mirrors `AUCTION4_LOT12_PRODUCT_ID` on the server.
const int auction4Lot12ProductId = 3833;
const num auction4Lot12IncrementCap = 200;

num getIncrementForPrice(num price, {int? productId}) {
  num step = 500;
  if (price < 500) {
    step = 10;
  } else if (price < 1500) {
    step = 20;
  } else if (price < 3000) {
    step = 50;
  } else if (price < 5000) {
    step = 100;
  } else if (price < 7500) {
    step = 200;
  }
  if (productId == auction4Lot12ProductId && step > auction4Lot12IncrementCap) {
    return auction4Lot12IncrementCap;
  }
  return step;
}

/// Public price from active bids only. A hidden proxy max is not the current bid.
num publicBidFloor({
  required List<num> activeAmounts,
  num openingPrice = 0,
}) {
  if (activeAmounts.isEmpty) return openingPrice;
  return activeAmounts.reduce((a, b) => a > b ? a : b);
}

/// Highest floor the ladder/swipe may use. Never prefer a stale
/// [highestActiveBid] when [currentPrice] has already moved higher.
num maxBidFloor({
  num? highestActiveBid,
  required num currentPrice,
  num? openingPrice,
}) {
  return [
    highestActiveBid,
    currentPrice,
    openingPrice,
  ].whereType<num>().fold<num>(0, (a, b) => a > b ? a : b);
}

/// Next legal one-step amount: floor + increment at that floor.
num nextOneStepBid({
  num? highestActiveBid,
  required num currentPrice,
  num? openingPrice,
  int? productId,
}) {
  final floor = maxBidFloor(
    highestActiveBid: highestActiveBid,
    currentPrice: currentPrice,
    openingPrice: openingPrice,
  );
  return floor + getIncrementForPrice(floor, productId: productId);
}

/// Builds [count] successive bid amounts starting from [basePrice],
/// recalculating the increment at each step so threshold crossings are
/// respected (e.g. 1480 +20 = 1500, then 1500 +50 = 1550, not +20).
List<num> buildBidSteps(num basePrice, int count, {int? productId}) {
  final steps = <num>[];
  num running = basePrice;
  for (int i = 0; i < count; i++) {
    final inc = getIncrementForPrice(running, productId: productId);
    running += inc;
    steps.add(running);
  }
  return steps;
}
