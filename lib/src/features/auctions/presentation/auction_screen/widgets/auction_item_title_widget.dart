import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';


class AuctionItemTitleWidget extends StatelessWidget {
  final AuctionModel auction;
  final AuctionProducts? activeProduct;

  const AuctionItemTitleWidget({
    super.key,
    required this.auction,
    this.activeProduct,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    final String title = activeProduct?.localizedName(locale).isNotEmpty == true
        ? activeProduct!.localizedName(locale)
        : auction.localizedTitle(locale);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Center(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
