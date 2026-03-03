import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/auction_screen.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/live_auction_screen.dart';

/// Wrapper that fetches the auction by ID and routes to the correct screen:
/// - Pre-auction / not yet started → AuctionScreen (details + max bid)
/// - Live phase → LiveAuctionScreen
class AuctionDetailsWrapper extends ConsumerWidget {
  final int auctionId;

  const AuctionDetailsWrapper({super.key, required this.auctionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionAsync = ref.watch(auctionDetailsProvider(auctionId));

    return auctionAsync.when(
      data: (auction) {
        // Determine if the auction is currently in the live phase
        final bool isInLivePhase =
            auction.isLive == true || auction.currentProduct != null;

        if (isInLivePhase) {
          return LiveAuctionScreen(auctionId: auctionId);
        } else {
          return AuctionScreen(auction);
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
