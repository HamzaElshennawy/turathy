import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/common_widgets/product_card.dart';
import '../../../../../../core/common_widgets/store_product_image.dart';
import '../../../../../../core/common_widgets/shimmer_widget/shimmer_widget.dart';
import '../../../../../../core/constants/app_functions/app_functions.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../main_screen.dart';
import '../../../../../products/data/products_repository.dart';
import '../../../../../search/presentation/widgets/filter_widget/filter_widget_controller.dart';

class ProductsListWidget extends StatelessWidget {
  const ProductsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.products.tr(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            Consumer(
              builder: (context, ref, child) {
                return TextButton(
                  onPressed: () {
                    ref
                        .read(filterWidgetControllerProvider.notifier)
                        .clearSelectedCategory();
                    ref.read(mainScreenTabIndexProvider.notifier).state = 2;
                  },
                  child: Text(
                    AppStrings.more.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 1.2,
                      height: 1.2,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        gapH4,
        Builder(
          builder: (context) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final isMobile = AppFunctions.isMobile(context: context);
            final cardWidth = isMobile
                ? screenWidth * 0.62
                : (MediaQuery.orientationOf(context) == Orientation.landscape
                      ? 280.0
                      : 300.0);
            final railHeight = cardWidth / StoreProductImage.frameAspect + 168;
            return SizedBox(
          height: railHeight,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final productsListValue = ref.watch(productsListProvider);
              return productsListValue.when(
                data: (data) {
                  if (data.isEmpty) {
                    return Center(child: Text(AppStrings.noThingFound.tr()));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemExtent: cardWidth,
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      final product = data[index];
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ProductCard(
                          product: product,
                          heroTag: 'products_list_${product.id}_$index',
                        ),
                      );
                    },
                  );
                },
                loading: () => GridView.builder(
                  shrinkWrap: true,
                  itemCount: 4,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: AppFunctions.isMobile(context: context)
                        ? 2
                        : 3,
                    childAspectRatio: .7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) =>
                      const ShimmerWidget(width: 400, height: 0),
                ),
                error: (error, stackTrace) =>
                    Center(child: Text(AppStrings.checkInternetConnection.tr())),
              );
            },
          ),
        );
          },
        ),
      ],
    );
  }
}
