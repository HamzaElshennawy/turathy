import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/home/domain/discovery_groups.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';

ProductModel _product(int id) {
  return ProductModel(
    id: id,
    title: 'coin',
    name: 'coin',
    description: 'slab',
    price: 12.0,
    imageUrl: 'https://example.com/$id.jpg',
    category: 'coins',
    brand: 'turathy',
    stock: 1,
    discount: 0.0,
    rating: 0.0,
    reviews: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('search groups live auctions, upcoming auctions, and store products', () {
    final groups = groupSearchResults([
      AuctionModel(id: 1, isLiveAuction: true, isLive: true, isExpired: false),
      AuctionModel(id: 2, isLiveAuction: false, isLive: false, isExpired: false),
      AuctionModel(id: 3, isLiveAuction: true, isLive: true, isExpired: true),
      _product(9),
      'ignored',
    ]);

    expect(groups.current.map((auction) => auction.id), [1]);
    expect(groups.upcoming.map((auction) => auction.id), [2]);
    expect(groups.store.map((product) => product.id), [9]);
    expect(groups.isEmpty, isFalse);
  });

  test('empty search results stay empty', () {
    expect(groupSearchResults(const []).isEmpty, isTrue);
  });

  test('category hub asks for current Live lots and future Open lots', () {
    final live = categoryHubAuctionQuery(live: true);
    final upcoming = categoryHubAuctionQuery(live: false);

    expect(live['type'], 'Live');
    expect(live['status'], 'current');
    expect(upcoming['type'], 'Open');
    expect(upcoming['status'], 'future');
    expect(live.containsKey('cat'), isFalse);
    expect(upcoming.containsKey('limit'), isFalse);
  });
}
