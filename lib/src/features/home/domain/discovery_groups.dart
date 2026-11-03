import '../../auctions/domain/auction_model.dart';
import '../../products/domain/product_model.dart';

class DiscoveryGroups {
  final List<AuctionModel> current;
  final List<AuctionModel> upcoming;
  final List<ProductModel> store;

  const DiscoveryGroups({
    required this.current,
    required this.upcoming,
    required this.store,
  });

  bool get isEmpty => current.isEmpty && upcoming.isEmpty && store.isEmpty;
}

DiscoveryGroups groupSearchResults(List<dynamic> results) {
  final current = <AuctionModel>[];
  final upcoming = <AuctionModel>[];
  final store = <ProductModel>[];

  for (final item in results) {
    if (item is ProductModel) {
      store.add(item);
    } else if (item is AuctionModel) {
      if (item.isExpired == true) continue;
      if (item.isLiveAuction || item.isLive == true) {
        current.add(item);
      } else {
        upcoming.add(item);
      }
    }
  }

  return DiscoveryGroups(current: current, upcoming: upcoming, store: store);
}
