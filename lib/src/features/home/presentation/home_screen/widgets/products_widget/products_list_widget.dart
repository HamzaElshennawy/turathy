import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/common_widgets/product_card.dart';
import '../../../../../../core/common_widgets/shimmer_widget/shimmer_widget.dart';
import '../../../../../../core/constants/app_functions/app_functions.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../products/data/products_repository.dart';

class ProductsListWidget extends StatelessWidget {
  const ProductsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.products.tr(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        gapH4,
        SizedBox(
          height: MediaQuery.of(context).size.width * .75,
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
                    itemExtent: MediaQuery.of(context).size.width * .7,
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      final product = data[index];
                      return ProductCard(
                        product: product,
                        heroTag: 'products_list_${product.id}_$index',
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
                    Center(child: Text('Error: $error')),
              );
            },
          ),
        ),
      ],
    );
  }
}
