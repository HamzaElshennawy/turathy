import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../features/auctions/domain/winning_auction_model.dart';
import '../../features/orders/domain/order_model.dart';
import '../../features/orders/presentation/shipping_details_screen.dart';
import '../constants/app_strings/app_strings.dart';
import 'custom_card.dart';
import 'primary_button.dart';

class WinningAuctionCard extends StatelessWidget {
  final WinningAuctionModel winningAuction;

  const WinningAuctionCard({
    super.key,
    required this.winningAuction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  winningAuction.auctionTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: winningAuction.sold 
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: winningAuction.sold ? Border.all(
                    color: theme.colorScheme.secondary,
                    width: 1,
                  ) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (winningAuction.sold) 
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    if (winningAuction.sold)
                      const SizedBox(width: 4),
                    Text(
                      winningAuction.sold 
                        ? AppStrings.alreadyPaid.tr()
                        : AppStrings.waitingForPayment.tr(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: winningAuction.sold 
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            AppStrings.currentProduct.tr(),
            winningAuction.product,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            AppStrings.price.tr(),
            winningAuction.formattedPrice,
            valueStyle: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            AppStrings.startedAt.tr(),
            winningAuction.formattedStartDate,
          ),
          if (!winningAuction.sold) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () {
                final order = OrderModel.fromWinningAuction(winningAuction);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShippingDetailsScreen(initialOrder: order),
                  ),
                );
              },
              text: AppStrings.proceedToPayment.tr(),
              isLoading: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {TextStyle? valueStyle}) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: valueStyle ?? theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
} 