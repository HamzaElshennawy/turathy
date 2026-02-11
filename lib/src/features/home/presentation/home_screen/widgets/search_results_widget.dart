import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/auction_card.dart';
import 'package:turathy/src/core/common_widgets/product_card.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';
import '../controllers/search_provider.dart';

class SearchResultsWidget extends ConsumerWidget {
  const SearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);

    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Sizes.p16),
              child: Text(
                AppStrings.noResultsFound,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(Sizes.p16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            if (item is ProductModel) {
              return SizedBox(
                height: 320, // Approximate height for ProductCard
                child: ProductCard(
                  product: item,
                  heroTag: 'search_product_${item.id}',
                ),
              );
            } else if (item is AuctionModel) {
              return SizedBox(
                height: 320, // Approximate height for AuctionCard
                child: AuctionCard(
                  product: item,
                  heroTag: 'search_auction_${item.id}',
                ),
              );
            }
            return const SizedBox();
          },
          separatorBuilder: (context, index) => gapH16,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
