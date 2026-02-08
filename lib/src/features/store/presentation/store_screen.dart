import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/product_card.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/home/data/category_repository.dart';
import 'package:turathy/src/features/products/data/products_repository.dart';
import 'package:turathy/src/features/home/domain/category_model.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsyncValue = ref.watch(productsListProvider);
    final categoriesAsyncValue = ref.watch(getAllCategoriesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Search Bar
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
                        // TODO: Implement filter dialog
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
                          setState(() {});
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

          // Categories Filter
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: categoriesAsyncValue.when(
                data: (categories) {
                  // Add "All" category at the beginning?
                  // Or assume user can deselect.
                  // Let's add specific category model logic if needed.
                  // For now, list categories.
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategoryId == category.id;
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
                            setState(() {
                              _selectedCategoryId = selected
                                  ? category.id
                                  : null;
                            });
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: gapH16),

          // Product Grid
          productsAsyncValue.when(
            data: (products) {
              // Filter products
              final filteredProducts = products.where((product) {
                final matchesSearch =
                    product.title?.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ) ??
                    false;
                final matchesCategory =
                    _selectedCategoryId == null ||
                    product.category ==
                        categoriesAsyncValue.value
                            ?.firstWhere(
                              (c) => c.id == _selectedCategoryId,
                              orElse: () => CategoryModel(id: -1),
                            )
                            .name; // Assuming filtering by name match or ID if possible.
                // Note: ProductModel has `category` as String. CategoryModel has `name` (String) and `id` (int).
                // We need to match efficiently. If backend provides category ID in product, use that.
                // ProductModel has `category` string. Let's assume it matches category name.

                return matchesSearch && matchesCategory;
              }).toList();

              if (filteredProducts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No products found')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.55, // Adjust card aspect ratio
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
            error: (error, stack) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $error'))),
          ),

          // Bottom padding for navigation bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
