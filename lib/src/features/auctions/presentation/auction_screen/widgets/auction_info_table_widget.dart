import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

class AuctionInfoTableWidget extends StatelessWidget {
  final AuctionModel auction;
  final AuctionProducts? currentProduct;

  const AuctionInfoTableWidget({
    super.key,
    required this.auction,
    this.currentProduct,
  });

  @override
  Widget build(BuildContext context) {
    // Use passed product or find active product based on name, or fallback
    final activeProduct =
        currentProduct ??
        auction.auctionProducts?.firstWhere(
          (p) => p.product == auction.currentProduct,
          orElse: () => AuctionProducts(),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              activeProduct?.product ?? auction.title ?? '',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          gapH16,
          Text(
            'basicData'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          gapH12,
          _buildInfoRow(
            context,
            'productType'.tr(),
            auction.type
                .tr(), // Type usually remains with auction, or could be product specific
          ),
          _buildInfoRow(
            context,
            'material'.tr(),
            activeProduct?.material ?? 'notSpecified'.tr(),
          ),
          _buildInfoRow(
            context,
            'approximateAge'.tr(),
            activeProduct?.approximateAge ?? 'notSpecified'.tr(),
          ),
          _buildInfoRow(
            context,
            'productCondition'.tr(),
            activeProduct?.condition ?? 'notSpecified'.tr(),
          ),
          _buildInfoRow(
            context,
            'origin'.tr(),
            activeProduct?.origin ?? 'notSpecified'.tr(),
          ),
          _buildInfoRow(
            context,
            'usage'.tr(),
            activeProduct?.usage ?? 'notSpecified'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
