import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/utils/customer_stage_filter.dart';

void main() {
  AuctionProducts p(int id) => AuctionProducts(id: id, productEn: 'Lot $id');
  AuctionBid bid({required int userId, required int productId}) => AuctionBid(
        userId: userId,
        productId: productId,
        bid: 100,
      );

  final products = [p(1), p(2), p(3), p(4)];
  final userBids = {1, 2, 3};
  final highest = <int, AuctionBid?>{
    1: bid(userId: 10, productId: 1), // winning
    2: bid(userId: 99, productId: 2), // losing
    3: bid(userId: 10, productId: 3), // winning
  };

  test('all returns every product', () {
    final result = filterProductsByCustomerStage(
      products: products,
      tab: CustomerStageTab.all,
      userBidProductIds: userBids,
      highestBids: highest,
      currentUserId: 10,
    );
    expect(result.map((e) => e.id), [1, 2, 3, 4]);
  });

  test('myBids only user participated', () {
    final result = filterProductsByCustomerStage(
      products: products,
      tab: CustomerStageTab.myBids,
      userBidProductIds: userBids,
      highestBids: highest,
      currentUserId: 10,
    );
    expect(result.map((e) => e.id), [1, 2, 3]);
  });

  test('winning only highest', () {
    final result = filterProductsByCustomerStage(
      products: products,
      tab: CustomerStageTab.winning,
      userBidProductIds: userBids,
      highestBids: highest,
      currentUserId: 10,
    );
    expect(result.map((e) => e.id), [1, 3]);
  });

  test('losing only outbid', () {
    final result = filterProductsByCustomerStage(
      products: products,
      tab: CustomerStageTab.losing,
      userBidProductIds: userBids,
      highestBids: highest,
      currentUserId: 10,
    );
    expect(result.map((e) => e.id), [2]);
  });
}
