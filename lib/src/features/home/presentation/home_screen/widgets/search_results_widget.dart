/// {@category Presentation}
///
/// A dynamic overlay for displaying real-time search and filter results.
/// 
/// [SearchResultsWidget] reactively listens to the [searchResultsProvider] to 
/// render a list of items that match the user's current query and filter 
/// criteria. It is capable of displaying a mixed feed of static products 
/// and time-sensitive auctions.
/// 
/// Display Logic:
/// - **Mixed Content**: Gracefully switches between [ProductCard] and [AuctionCard] 
///   by performing runtime type checks on the generic result list.
/// - **Spatial Consistency**: Wraps cards in 320dp containers to maintain a 
///   predictable scrolling rhythm.
/// - **Hero Integration**: Generates scoped `heroTag` strings to prevent collision 
///   with main-screen cards during navigation transitions.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turathy/src/core/common_widgets/auction_card.dart';
import 'package:turathy/src/core/common_widgets/product_card.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';
import '../controllers/search_provider.dart';

/// A scrollable list that renders the outcome of a search query.
class SearchResultsWidget extends ConsumerWidget {
  /// Creates a [SearchResultsWidget].
  const SearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);

    return searchResults.when(
      data: (results) {
        // ── Empty State ──────────────────────────────────────────────────────
        if (results.isEmpty) {
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

        // ── Result Feed ──────────────────────────────────────────────────────
        return ListView.separated(
          padding: const EdgeInsets.all(Sizes.p16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];

            // Branch: Render as a standard store product
            if (item is ProductModel) {
              return SizedBox(
                height: 320, // Design: Enforce uniform height for grid alignment
                child: ProductCard(
                  product: item,
                  heroTag: 'search_product_${item.id}',
                ),
              );
            } 
            
            // Branch: Render as a live or upcoming auction
            else if (item is AuctionModel) {
              return SizedBox(
                height: 320,
                child: AuctionCard(
                  auction: item,
                  heroTag: 'search_auction_${item.id}',
                ),
              );
            }
            
            return const SizedBox();
          },
          separatorBuilder: (context, index) => gapH16,
        );
      },
      
      // ── States ─────────────────────────────────────────────────────────────
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text(AppStrings.checkInternetConnection.tr())),
    );
  }
}
