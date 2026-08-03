import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';

enum CustomerStageTab { all, myBids, winning, losing }

/// Pure filter for auction lot lists by customer bidding stage.
List<AuctionProducts> filterProductsByCustomerStage({
  required List<AuctionProducts> products,
  required CustomerStageTab tab,
  required Set<int> userBidProductIds,
  required Map<int, AuctionBid?> highestBids,
  int? currentUserId,
}) {
  final uid = currentUserId ?? CachedVariables.userId;
  switch (tab) {
    case CustomerStageTab.all:
      return List<AuctionProducts>.from(products);
    case CustomerStageTab.myBids:
      return products
          .where((p) => p.id != null && userBidProductIds.contains(p.id))
          .toList();
    case CustomerStageTab.winning:
      return products.where((p) {
        if (p.id == null || !userBidProductIds.contains(p.id)) return false;
        return highestBids[p.id]?.userId == uid;
      }).toList();
    case CustomerStageTab.losing:
      return products.where((p) {
        if (p.id == null || !userBidProductIds.contains(p.id)) return false;
        final highest = highestBids[p.id];
        return highest != null && highest.userId != uid;
      }).toList();
  }
}
