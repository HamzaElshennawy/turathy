import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/product_card.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/analytics/analytics_service.dart';
import 'package:turathy/src/features/products/data/products_repository.dart';
import 'package:turathy/src/features/home/data/category_repository.dart';

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
    final productsAsyncValue = ref.watch(filteredProductsProvider);
    final categoriesAsyncValue = ref.watch(getAllCategoriesProvider);
    final filterState = ref.watch(filterWidgetControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(filteredProductsProvider);
          ref.invalidate(getAllCategoriesProvider);
          await ref.read(filteredProductsProvider.future);
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
                            builder: (context) => FractionallySizedBox(
                              heightFactor: 0.85,
                              child: FilterWidget(
                                contentType: FilterContentType.store,
                                onApply: () => ref.invalidate(filteredProductsProvider),
                                onClear: () => ref.invalidate(filteredProductsProvider),
                              ),
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
                if (products.isEmpty) {
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
                      return ProductCard(product: products[index]);
                    }, childCount: products.length),
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
