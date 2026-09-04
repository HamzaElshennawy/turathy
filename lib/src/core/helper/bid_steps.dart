/// Bid increment ladder for Turathy mobile (must match server thresholds).
library;

num getIncrementForPrice(num price) {
  if (price < 500) return 10;
  if (price < 1500) return 20;
  if (price < 3000) return 50;
  if (price < 5000) return 100;
  if (price < 7500) return 200;
  return 500;
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
}) {
  final floor = maxBidFloor(
    highestActiveBid: highestActiveBid,
    currentPrice: currentPrice,
    openingPrice: openingPrice,
  );
  return floor + getIncrementForPrice(floor);
}

/// Builds [count] successive bid amounts starting from [basePrice],
/// recalculating the increment at each step so threshold crossings are
/// respected (e.g. 1480 +20 = 1500, then 1500 +50 = 1550, not +20).
List<num> buildBidSteps(num basePrice, int count) {
  final steps = <num>[];
  num running = basePrice;
  for (int i = 0; i < count; i++) {
    final inc = getIncrementForPrice(running);
    running += inc;
    steps.add(running);
  }
  return steps;
}
