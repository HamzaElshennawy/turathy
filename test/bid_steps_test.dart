import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/bid_steps.dart';

void main() {
  test('buildBidSteps returns 50 steps', () {
    expect(buildBidSteps(60, 50).length, 50);
  });

  test('buildBidSteps respects increment threshold crossings', () {
    final steps = buildBidSteps(1480, 3);
    expect(steps[0], 1500); // 1480 + 20
    expect(steps[1], 1550); // 1500 + 50
    expect(steps[2], 1600);
  });

  test('hidden proxy max does not raise the public floor', () {
    final floor = publicBidFloor(activeAmounts: [3100], openingPrice: 3000);
    expect(floor, 3100);
    expect(floor + getIncrementForPrice(floor), 3200);
    expect(5000 + getIncrementForPrice(5000), 5200);
  });

  test('auction 4 lot 12 caps the 500 tier at 200', () {
    expect(getIncrementForPrice(8600, productId: auction4Lot12ProductId), 200);
    expect(getIncrementForPrice(8600), 500);
    expect(getIncrementForPrice(3000, productId: auction4Lot12ProductId), 100);
    expect(
      nextOneStepBid(currentPrice: 8600, productId: auction4Lot12ProductId),
      8800,
    );
  });
}
