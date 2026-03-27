import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/home/presentation/home_screen/widgets/products_widget/products_list_widget.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/products/data/products_repository.dart';
import 'package:turathy/src/features/home/data/category_repository.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../authintication/presentation/auth_controller.dart';
import 'widgets/products_widget/live_auctions_widget.dart';

class HomeScreen extends ConsumerWidget {
  final ScrollController? scrollController;
  const HomeScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.p8),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(homeLiveAuctionsProvider);
                ref.invalidate(openAuctionsProvider);
                ref.invalidate(productsListProvider);
                ref.invalidate(getAllCategoriesProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    gapH12,
                    Consumer(
                      builder: (context, ref, child) {
                        return const Column(
                          children: [
                            LiveAuctionsWidget(),
                            ProductsListWidget(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
