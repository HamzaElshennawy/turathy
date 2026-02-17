import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/home/presentation/home_screen/widgets/products_widget/products_list_widget.dart';
import 'package:turathy/src/features/home/presentation/home_screen/widgets/search_widget.dart';
import 'package:turathy/src/features/home/presentation/home_screen/widgets/search_results_widget.dart';
import 'package:turathy/src/features/home/presentation/home_screen/controllers/search_provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/home/presentation/home_screen/widgets/categories_widget/category_widget.dart';
import 'package:turathy/src/features/search/presentation/widgets/filter_widget/filter_widget_controller.dart';
import 'package:turathy/src/features/search/presentation/widgets/search_list_widget.dart';
import 'widgets/products_widget/live_auctions_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.all(Sizes.p8),
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authControllerProvider).valueOrNull;
              if (user == null) {
                return const SizedBox();
              }
              return Column(
                children: [
                  Row(
                    children: [
                      //Expanded(
                      //  child: Text(
                      //    '👋 ${AppStrings.hi.tr()}, ${user.name}',
                      //    style: Theme.of(context).textTheme.titleMedium,
                      //  ),
                      //),
                    ],
                  ),
                  const Divider(),
                ],
              );
            },
          ),
          // Search Widget fixed at the top
          const SearchWidget(),
          gapH12,
          Expanded(
            child: searchQuery.isNotEmpty
                ? const SearchResultsWidget()
                : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CategoriesWidget(),
                          gapH12,
                          Consumer(
                            builder: (context, ref, child) {
                              //final filterState = ref.watch(
                              //  filterWidgetControllerProvider,
                              //);
                              //if ((filterState.selectedCategoryID != -1 &&
                              //        filterState.selectedCategoryID != null) ||
                              //    (filterState.selectedColor != null &&
                              //        filterState.selectedColor!.isNotEmpty) ||
                              //    (filterState.selectedSize != null &&
                              //        filterState.selectedSize!.isNotEmpty) ||
                              //    filterState.isAllOffersSelected) {
                              //  return SizedBox(
                              //    height:
                              //        MediaQuery.of(context).size.height * 0.6,
                              //    child: const SearchListWidget(),
                              //  );
                              //}
                              return Column(
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
