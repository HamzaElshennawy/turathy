import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common_widgets/product_card.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings/app_strings.dart';
import '../../../auctions/data/auctions_repository.dart'
    hide productsRepositoryProvider;
import '../../../auctions/domain/auction_model.dart';
import '../../../products/data/products_repository.dart';
import '../../../products/domain/product_model.dart';
import '../../../search/presentation/widgets/filter_widget/filter_widget_controller.dart';
import 'category_auction_tile.dart';
import '../widgets/discovery_section.dart';

class CategoryHubScreen extends ConsumerWidget {
  const CategoryHubScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(categoryLiveAuctionsProvider(categoryId));
    final upcoming = ref.watch(categoryUpcomingAuctionsProvider(categoryId));
    final products = ref.watch(filteredProductsProvider);
    final selectedId = ref.watch(filterWidgetControllerProvider).selectedCategoryID;

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryLiveAuctionsProvider(categoryId));
          ref.invalidate(categoryUpcomingAuctionsProvider(categoryId));
          ref.invalidate(filteredProductsProvider);
          await Future.wait([
            ref.read(categoryLiveAuctionsProvider(categoryId).future),
            ref.read(categoryUpcomingAuctionsProvider(categoryId).future),
            ref.read(filteredProductsProvider.future),
          ]);
        },
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (selectedId != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: InputChip(
                  label: Text(categoryName),
                  onDeleted: () {
                    ref
                        .read(filterWidgetControllerProvider.notifier)
                        .clearSelectedCategory();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            gapH12,
            _AuctionBlock(
              title: AppStrings.currentAuctions.tr(),
              sectionKey: const Key('discovery-current'),
              value: live,
            ),
            _AuctionBlock(
              title: AppStrings.futureAuctions.tr(),
              sectionKey: const Key('discovery-upcoming'),
              value: upcoming,
            ),
            _ProductBlock(value: products),
          ],
        ),
      ),
    );
  }
}

class _AuctionBlock extends StatelessWidget {
  const _AuctionBlock({
    required this.title,
    required this.sectionKey,
    required this.value,
  });

  final String title;
  final Key sectionKey;
  final AsyncValue<List<AuctionModel>> value;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (auctions) => DiscoverySection(
        sectionKey: sectionKey,
        title: title,
        emptyMessage: AppStrings.noThingFound.tr(),
        itemCount: auctions.length,
        railHeight: 280,
        itemBuilder: (context, index) {
          return SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.72,
            child: CategoryAuctionTile(auction: auctions[index]),
          );
        },
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(AppStrings.checkInternetConnection.tr()),
      ),
    );
  }
}

class _ProductBlock extends StatelessWidget {
  const _ProductBlock({required this.value});

  final AsyncValue<List<ProductModel>> value;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (products) => DiscoverySection(
        sectionKey: const Key('discovery-store'),
        title: AppStrings.store.tr(),
        emptyMessage: AppStrings.noProductsInCategory.tr(),
        itemCount: products.length,
        grid: true,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            heroTag: 'category_product_${product.id}',
          );
        },
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(AppStrings.checkInternetConnection.tr()),
      ),
    );
  }
}
