import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/product_card.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/analytics/analytics_service.dart';
import 'package:turathy/src/features/home/data/category_repository.dart';
import 'package:turathy/src/features/home/domain/category_model.dart';
import 'package:turathy/src/features/products/data/products_repository.dart';

import '../../search/presentation/widgets/filter_widget/filter_widget.dart';
import '../../search/presentation/widgets/filter_widget/filter_widget_controller.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'store_screen');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsyncValue = ref.watch(productsListProvider);
    final categoriesAsyncValue = ref.watch(getAllCategoriesProvider);
    final filterState = ref.watch(filterWidgetControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsListProvider);
          ref.invalidate(getAllCategoriesProvider);
          await ref.read(productsListProvider.future);
          await ref.read(getAllCategoriesProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => const FractionallySizedBox(
                              heightFactor: 0.85,
                              child: FilterWidget(),
                            ),
                          );
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: AppStrings.search.tr(),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (value) {
                            ref
                                .read(filterWidgetControllerProvider.notifier)
                                .setSearchText(value);
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: categoriesAsyncValue.when(
                  data: (categories) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected =
                            filterState.selectedCategoryID == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              category.name ?? '',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              ref
                                  .read(filterWidgetControllerProvider.notifier)
                                  .selectCategory(index);
                              if (selected &&
                                  category.id != null &&
                                  category.name?.isNotEmpty == true) {
                                AnalyticsService.logCategorySelected(
                                  categoryId: category.id!,
                                  categoryName: category.name!,
                                  source: 'store_screen',
                                );
                              }
                            },
                            backgroundColor: Colors.grey.shade200,
                            selectedColor: const Color(0xFF1B5E20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                            showCheckmark: false,
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: gapH16),
            productsAsyncValue.when(
              data: (products) {
                final filteredProducts = products.where((product) {
                  final searchText = filterState.searchText ?? '';
                  final matchesSearch = product.title
                          ?.toLowerCase()
                          .contains(searchText.toLowerCase()) ??
                      false;

                  final matchesCategory =
                      filterState.selectedCategoryID == null ||
                          filterState.selectedCategoryID == -1 ||
                          product.category ==
                              categoriesAsyncValue.value
                                  ?.firstWhere(
                                    (c) =>
                                        c.id == filterState.selectedCategoryID,
                                    orElse: () => CategoryModel(id: -1),
                                  )
                                  .name;

                  final matchesMinPrice = filterState.minPrice == null ||
                      (product.price != null &&
                          product.price! >= filterState.minPrice!);
                  final matchesMaxPrice = filterState.maxPrice == null ||
                      (product.price != null &&
                          product.price! <= filterState.maxPrice!);

                  final matchesCountry = filterState.country == null ||
                      filterState.country!.isEmpty ||
                      product.country == filterState.country;

                  final matchesDateFrom = filterState.dateFrom == null ||
                      filterState.dateFrom == -1 ||
                      (product.date != null &&
                          product.date! >= filterState.dateFrom!);
                  final matchesDateTo = filterState.dateTo == null ||
                      filterState.dateTo == -1 ||
                      (product.date != null &&
                          product.date! <= filterState.dateTo!);

                  final matchesDenom = filterState.denomination == null ||
                      filterState.denomination!.isEmpty ||
                      product.denomination
                              ?.toLowerCase()
                              .contains(filterState.denomination!.toLowerCase()) ==
                          true;

                  final matchesGraded = filterState.isGraded == null ||
                      product.isGraded == filterState.isGraded;

                  final matchesGradingCompany =
                      filterState.gradingCompany == null ||
                          filterState.gradingCompany!.isEmpty ||
                          product.gradingCompany == filterState.gradingCompany;

                  final matchesGradeFrom = filterState.gradeFrom == null ||
                      filterState.gradeFrom == -1 ||
                      (product.grade != null &&
                          product.grade! >= filterState.gradeFrom!);
                  final matchesGradeTo = filterState.gradeTo == null ||
                      filterState.gradeTo == -1 ||
                      (product.grade != null &&
                          product.grade! <= filterState.gradeTo!);

                  final matchesMetalType = filterState.metalType == null ||
                      filterState.metalType!.isEmpty ||
                      product.metalType
                              ?.toLowerCase()
                              .contains(filterState.metalType!.toLowerCase()) ==
                          true;

                  final matchesMetalFineness =
                      filterState.metalFineness == null ||
                          filterState.metalFineness!.isEmpty ||
                          product.metalFineness?.toLowerCase().contains(
                                  filterState.metalFineness!.toLowerCase()) ==
                              true;

                  return matchesSearch &&
                      matchesCategory &&
                      matchesMinPrice &&
                      matchesMaxPrice &&
                      matchesCountry &&
                      matchesDateFrom &&
                      matchesDateTo &&
                      matchesDenom &&
                      matchesGraded &&
                      matchesGradingCompany &&
                      matchesGradeFrom &&
                      matchesGradeTo &&
                      matchesMetalType &&
                      matchesMetalFineness;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text('No products found')),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.55,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return ProductCard(product: filteredProducts[index]);
                    }, childCount: filteredProducts.length),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $error')),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
