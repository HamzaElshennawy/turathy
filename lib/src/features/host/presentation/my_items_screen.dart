import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/auction_screen.dart';
import 'package:turathy/src/features/products/data/products_repository.dart';
import 'package:turathy/src/features/products/presentation/product_screen.dart';
import 'package:turathy/src/features/host/presentation/create_item_screen.dart';

class MyItemsScreen extends ConsumerWidget {
  const MyItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.hostDashboard.tr()),
          bottom: TabBar(
            tabs: [
              Tab(text: AppStrings.myProducts.tr()),
              Tab(text: AppStrings.myAuctions.tr()),
            ],
            indicatorColor: const Color(0xFF2D4739),
            labelColor: const Color(0xFF2D4739),
            unselectedLabelColor: Colors.grey,
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateItemScreen()),
            );
          },
          label: Text(AppStrings.addNewItem.tr()),
          icon: const Icon(Icons.add),
          backgroundColor: const Color(0xFF2D4739),
        ),
        body: const TabBarView(
          children: [_MyProductsList(), _MyAuctionsList()],
        ),
      ),
    );
  }
}

class _MyAuctionsList extends ConsumerWidget {
  const _MyAuctionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(userAuctionsProvider('Live'));

    return auctionsAsync.when(
      data: (auctions) {
        if (auctions.isEmpty) {
          return Center(child: Text(AppStrings.noAuctionsCreatedYet.tr()));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userAuctionsProvider('Live'));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: auctions.length,
            separatorBuilder: (_, __) => gapH12,
            itemBuilder: (context, index) {
              final auction = auctions[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuctionScreen(auction),
                      ),
                    );
                  },
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(auction.imageUrl ?? ''),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                  ),
                  title: Text(
                    auction
                            .localizedTitle(context.locale.languageCode)
                            .isNotEmpty
                        ? auction.localizedTitle(context.locale.languageCode)
                        : AppStrings.untitledAuction.tr(),
                  ),
                  subtitle: Row(
                    children: [
                      Text('${AppStrings.startPrice.tr()}: '),
                      Text(
                        '${auction.minBidPrice ?? 0} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SvgPicture.asset('assets/icons/RSA.svg', height: 14),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      auction.isLive == true
                          ? AppStrings.live.tr()
                          : (auction.isExpired == true
                                ? AppStrings.ended.tr()
                                : AppStrings.upcoming.tr()),
                    ),
                    backgroundColor: auction.isLive == true
                        ? Colors.red.shade100
                        : (auction.isExpired == true
                              ? Colors.grey.shade200
                              : Colors.green.shade100),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            },
          ),
        );
      },
      error: (e, s) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MyProductsList extends ConsumerWidget {
  const _MyProductsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(myProductsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(child: Text(AppStrings.noProductsCreatedYet.tr()));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myProductsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => gapH12,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductScreen(product: product),
                      ),
                    );
                  },
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(product.fullImageUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                  ),
                  title: Text(
                    product.title ??
                        product.name ??
                        AppStrings.untitledProduct.tr(),
                  ),
                  subtitle: Row(
                    children: [
                      Text('${AppStrings.price.tr()}: '),
                      Text(
                        '${product.price ?? 0} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SvgPicture.asset('assets/icons/RSA.svg', height: 14),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      error: (e, s) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
