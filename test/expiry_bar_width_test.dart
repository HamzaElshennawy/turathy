import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_expiry_clock.dart';

void main() {
  test('the last-30-seconds bar stays inside the pill', () {
    expect(expiryBarWidth(200, 1.4), 200);
    expect(expiryBarWidth(200, 0.5), 100);
    expect(expiryBarWidth(200, -1), 0);
  });
}
