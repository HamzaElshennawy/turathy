import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/share/item_share_helper.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/utils/customer_stage_filter.dart';

void main() {
  test('app package helpers smoke', () {
    expect(
      ItemShareHelper.auctionLotUrl(auctionId: 1).contains('/auctions/1'),
      isTrue,
    );
    expect(CustomerStageTab.values.length, 4);
  });
}
