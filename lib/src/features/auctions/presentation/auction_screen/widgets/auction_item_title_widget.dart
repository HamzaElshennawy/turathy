import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/auction_price_helpers.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';


class AuctionItemTitleWidget extends StatelessWidget {
  final AuctionModel auction;
  final AuctionProducts? activeProduct;

  const AuctionItemTitleWidget({
    super.key,
    required this.auction,
    this.activeProduct,
  });

  int _fallbackLotIndex(AuctionProducts product) {
    final products = auction.auctionProducts;
    if (products == null) return 1;
    final idx = products.indexWhere((p) => p.id == product.id);
    return idx < 0 ? 1 : idx + 1;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    final String title = activeProduct?.localizedName(locale).isNotEmpty == true
        ? activeProduct!.localizedName(locale)
        : auction.localizedTitle(locale);

    final product = activeProduct;
    final int? lotNumber = product == null
        ? null
        : displayLotNumber(product, fallbackIndex: _fallbackLotIndex(product));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          if (lotNumber != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2D4739).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2D4739).withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '${AppStrings.itemNumber.tr()}: $lotNumber',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2D4739),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
