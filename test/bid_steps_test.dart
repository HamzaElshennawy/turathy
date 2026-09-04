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
}
