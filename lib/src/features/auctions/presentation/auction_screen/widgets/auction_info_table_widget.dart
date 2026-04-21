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
    final locale = context.locale.languageCode;

    // Use passed product or find active product based on name, or fallback
    final activeProduct =
        currentProduct ??
        auction.auctionProducts?.firstWhere(
          (p) => p.localizedName(locale) == auction.currentProduct,
          orElse: () => AuctionProducts(),
        );

    final String title = activeProduct?.localizedName(locale).isNotEmpty == true
        ? activeProduct!.localizedName(locale)
        : auction.localizedTitle(locale);

    final String description =
        activeProduct?.localizedDescription(locale).isNotEmpty == true
        ? activeProduct!.localizedDescription(locale)
        : auction.localizedDescription(locale);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Description
          if (description.isNotEmpty) ...[
            gapH12,
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
          if (activeProduct != null) ...[
            gapH16,
            _InfoRow(
              label: 'itemType'.tr(),
              value: activeProduct!.itemType,
            ),
            _InfoRow(
              label: 'country'.tr(),
              value: activeProduct!.country,
            ),
            _InfoRow(
              label: 'denomination'.tr(),
              value: activeProduct!.denomination,
            ),
            _InfoRow(
              label: 'gradingCompany'.tr(),
              value: activeProduct!.gradingCompany,
            ),
            _InfoRow(
              label: 'gradeDesignation'.tr(),
              value: activeProduct!.gradeDesignation,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim();
    if (displayValue == null || displayValue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayValue,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
