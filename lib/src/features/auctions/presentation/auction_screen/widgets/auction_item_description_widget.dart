import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

class AuctionItemDescriptionWidget extends StatelessWidget {
  final AuctionModel auction;
  final AuctionProducts? activeProduct;

  const AuctionItemDescriptionWidget({
    super.key,
    required this.auction,
    this.activeProduct,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    final String description =
        activeProduct?.localizedDescription(locale).isNotEmpty == true
            ? activeProduct!.localizedDescription(locale)
            : auction.localizedDescription(locale);

    if (description.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        description,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
      ),
    );
  }
}
