import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/shimmer_widget/shimmer_widget.dart';
import 'package:turathy/src/features/products/data/products_repository.dart';
import 'package:turathy/src/features/products/presentation/product_screen.dart';

class ProductDetailsWrapper extends ConsumerWidget {
  final int productId;

  const ProductDetailsWrapper({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsyncValue = ref.watch(productDetailsProvider(productId));

    return Scaffold(
      body: productAsyncValue.when(
        data: (product) => ProductScreen(product: product),
        loading: () => _buildShimmerLoading(),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppBar placeholder
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerWidget(
                  width: 40,
                  height: 40,
                  containerShape: BoxShape.circle,
                ),
                const ShimmerWidget(width: 150, height: 20),
                const ShimmerWidget(
                  width: 40,
                  height: 40,
                  containerShape: BoxShape.circle,
                ),
              ],
            ),
          ),
          // Image placeholder
          const ShimmerWidget(width: double.infinity, height: 300),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder
                const Center(child: ShimmerWidget(width: 200, height: 24)),
                const SizedBox(height: 16),
                // Description placeholder
                const ShimmerWidget(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const ShimmerWidget(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const ShimmerWidget(width: 200, height: 16),
                const SizedBox(height: 24),
                // Data rows placeholder
                for (int i = 0; i < 5; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerWidget(width: 100, height: 16),
                      const ShimmerWidget(width: 100, height: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
