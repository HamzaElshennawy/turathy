import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/horizontal_auction_card.dart';
import 'package:turathy/src/core/common_widgets/horizontal_product_card.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';
import 'package:turathy/src/routing/app_router.dart';
import 'package:turathy/src/routing/rout_constants.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.likes.tr()),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: AppStrings.auctions.tr()),
              Tab(text: AppStrings.products.tr()),
              Tab(text: AppStrings.watchlist.tr()),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LikedAuctionsList(),
            _LikedProductsList(),
            _WatchedLotsList(),
          ],
        ),
      ),
    );
  }
}

class _LikedAuctionsList extends ConsumerWidget {
  const _LikedAuctionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesControllerProvider);

    return favoritesState.when(
      data: (state) {
        if (state.likedAuctions.isEmpty) {
          return Center(child: Text(AppStrings.noResultsFound.tr()));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.likedAuctions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return HorizontalAuctionCard(product: state.likedAuctions[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _LikedProductsList extends ConsumerWidget {
  const _LikedProductsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesControllerProvider);

    return favoritesState.when(
      data: (state) {
        if (state.likedProducts.isEmpty) {
          return Center(child: Text(AppStrings.noResultsFound.tr()));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.likedProducts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return HorizontalProductCard(product: state.likedProducts[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _WatchedLotsList extends ConsumerWidget {
  const _WatchedLotsList();

  String _imageUrl(AuctionProducts lot) {
    final raw = (lot.imageUrl != null && lot.imageUrl!.isNotEmpty)
        ? lot.imageUrl!
        : (lot.images != null && lot.images!.isNotEmpty ? lot.images!.first : '');
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '${EndPoints.baseUrl}$raw';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesControllerProvider);

    return favoritesState.when(
      data: (state) {
        if (state.watchedLots.isEmpty) {
          return Center(child: Text(AppStrings.noResultsFound.tr()));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.watchedLots.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final lot = state.watchedLots[index];
            final image = _imageUrl(lot);
            final lotLabel = lot.lotNumber != null
                ? '${AppStrings.itemNumber.tr()}: ${lot.lotNumber}'
                : '';
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final auctionId = lot.auctionId;
                  if (auctionId == null) return;
                  goRouter.pushNamed(
                    RouteConstants.auctionDetails,
                    pathParameters: {'id': auctionId.toString()},
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: image.isEmpty
                              ? Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_outlined),
                                )
                              : CachedNetworkImage(
                                  imageUrl: image,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lot.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (lotLabel.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                lotLabel,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.watchlist.tr(),
                        icon: const Icon(
                          Icons.favorite,
                          color: Color(0xFF2D4739),
                        ),
                        onPressed: () {
                          ref
                              .read(favoritesControllerProvider.notifier)
                              .toggleWatchLot(lot);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
