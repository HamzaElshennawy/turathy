import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/common_widgets/auction_card.dart';
import '../../../../core/common_widgets/shimmer_widget/shimmer_widget.dart';
import '../../../../core/constants/app_functions/app_functions.dart';
import '../../../../core/constants/app_images/app_images.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings/app_strings.dart';
import '../../../auctions/data/auctions_repository.dart';

class SearchListWidget extends ConsumerWidget {
  const SearchListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(searchProductsProvider);
    return result.when(
        skipLoadingOnRefresh: false,
        data: (data) {
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppImages.dissatisfied,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurface,
                        BlendMode.srcIn),
                  ),
                  gapH8,
                  Text(
                    AppStrings.noThingFound.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(searchProductsProvider);
              },
              child: GridView.builder(
                itemCount: data.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        AppFunctions.isMobile(context: context) ? 2 : 3,
                    childAspectRatio: .7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8),
                itemBuilder: (BuildContext context, int index) {
                  final product = data[index];
                  return AuctionCard(
                    product: product,
                  );
                },
              ),
            ),
          );
        },
        loading: () => Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                itemCount: 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        AppFunctions.isMobile(context: context) ? 2 : 3,
                    childAspectRatio: .7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8),
                itemBuilder: (context, index) =>
                    const ShimmerWidget(width: 400, height: 0),
              ),
            ),
        error: (error, stackTrace) => Center(
              child: Text('Error: $error'),
            ));
  }
}
