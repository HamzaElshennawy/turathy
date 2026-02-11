import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/horizontal_auction_card.dart';
import 'package:turathy/src/core/common_widgets/horizontal_product_card.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.likes.tr()),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: AppStrings.auctions.tr()),
              Tab(text: AppStrings.products.tr()),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_LikedAuctionsList(), _LikedProductsList()],
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
