import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turathy/src/core/common_widgets/product_card.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/home/domain/discovery_groups.dart';
import 'package:turathy/src/features/home/presentation/category_hub/category_auction_tile.dart';
import 'package:turathy/src/features/home/presentation/widgets/discovery_section.dart';
import '../controllers/search_provider.dart';

/// Grouped home-search results: current auctions, upcoming auctions, store.
class SearchResultsWidget extends ConsumerWidget {
  const SearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);

    return searchResults.when(
      data: (results) {
        final groups = groupSearchResults(results);
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.p16),
              child: Text(
                AppStrings.noResultsFound.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(Sizes.p16),
          children: [
            DiscoverySection(
              sectionKey: const Key('discovery-current'),
              title: AppStrings.currentAuctions.tr(),
              emptyMessage: AppStrings.noThingFound.tr(),
              itemCount: groups.current.length,
              railHeight: 280,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.78,
                  child: CategoryAuctionTile(auction: groups.current[index]),
                );
              },
            ),
            DiscoverySection(
              sectionKey: const Key('discovery-upcoming'),
              title: AppStrings.futureAuctions.tr(),
              emptyMessage: AppStrings.noThingFound.tr(),
              itemCount: groups.upcoming.length,
              railHeight: 280,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.78,
                  child: CategoryAuctionTile(auction: groups.upcoming[index]),
                );
              },
            ),
            DiscoverySection(
              sectionKey: const Key('discovery-store'),
              title: AppStrings.store.tr(),
              emptyMessage: AppStrings.noProductsFound.tr(),
              itemCount: groups.store.length,
              grid: true,
              itemBuilder: (context, index) {
                final product = groups.store[index];
                return ProductCard(
                  product: product,
                  heroTag: 'search_product_${product.id}',
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text(AppStrings.checkInternetConnection.tr())),
    );
  }
}
