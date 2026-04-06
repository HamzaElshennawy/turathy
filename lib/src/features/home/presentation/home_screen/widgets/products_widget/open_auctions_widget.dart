import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/common_widgets/auction_card.dart';
import '../../../../../../core/common_widgets/shimmer_widget/shimmer_widget.dart';
import '../../../../../../core/constants/app_functions/app_functions.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../auctions/data/auctions_repository.dart';

class OpenAuctionsWidget extends StatelessWidget {
  const OpenAuctionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.openAuctions.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        gapH4,
        SizedBox(
          height: AppFunctions.isMobile(context: context)
              ? MediaQuery.of(context).size.width * 0.9
              : (MediaQuery.of(context).orientation == Orientation.landscape
                    ? 360
                    : 400),
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final openAuctionsListValue = ref.watch(openAuctionsProvider);
              return openAuctionsListValue.when(
                data: (data) {
                  if (data.isEmpty) {
                    return Center(child: Text(AppStrings.noThingFound.tr()));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemExtent: AppFunctions.isMobile(context: context)
                        ? MediaQuery.of(context).size.width * .7
                        : (MediaQuery.of(context).orientation ==
                                  Orientation.landscape
                              ? 290
                              : 300),
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      final product = data[index];
                      return AuctionCard(
                        auction: product,
                        heroTag: 'open_auctions_${product.id}_$index',
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
        ),
      ],
    );
  }
}
