import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/all_auctions_screen.dart';

import '../../../../../../core/common_widgets/auction_card.dart';
import '../../../../../../core/common_widgets/shimmer_widget/shimmer_widget.dart';
import '../../../../../../core/constants/app_functions/app_functions.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../auctions/data/auctions_repository.dart';

class LiveAuctionsWidget extends StatelessWidget {
  const LiveAuctionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.liveAuctions.tr(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllAuctionsScreen(),
                  ),
                );
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
            ),
          ],
        ),
        gapH24,
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.9,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final productsListValue = ref.watch(homeLiveAuctionsProvider);
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
                      return AuctionCard(
                        product: product,
                        heroTag: 'live_auctions_${product.id}_$index',
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
