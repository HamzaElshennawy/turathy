/// {@category Components}
///
/// A specialized card for representing an auction victory in the "My Wins" gallery.
/// 
/// This widget serves as a summary and gateway for post-auction fulfillment:
/// - **Visual Status Tracking**: Uses distinct color-coded badges to indicate if payment is 'Already Paid' or 'Waiting'.
/// - **Fulfillment Bridge**: For unpaid wins, provides a direct CTA to [OrderConfirmationScreen].
/// - **Transaction History**: Offers a quick shortcut to [MyPaymentsScreen] to view receipts.
/// - **Data Presentation**: Displays bid price, product name, and auction timing in a clean, structured table.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/auctions/domain/winning_auction_model.dart';
import '../../features/auctions/presentation/auction_screen/my_payments_screen.dart';
import '../../features/orders/domain/order_model.dart';
import '../../features/orders/presentation/order_confirmation_screen.dart';
import '../constants/app_strings/app_strings.dart';
import 'custom_card.dart';
import 'primary_button.dart';

/// A display card for summarizing won auctions and facilitating payments.
class WinningAuctionCard extends StatelessWidget {
  /// Structured data containing the price, title, and payment status of the win.
  final WinningAuctionModel winningAuction;

  /// Creates a [WinningAuctionCard] for the given [winningAuction] instance.
  const WinningAuctionCard({super.key, required this.winningAuction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title & Status Layer ──────────────────────────────────────────
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
              _buildStatusBadge(theme),
            ],
          ),
          const SizedBox(height: 16),

          // ── Metadata Table Section ────────────────────────────────────────
          _buildInfoRow(context, AppStrings.currentProduct.tr(), winningAuction.product),
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

          _buildInfoRow(context, AppStrings.startedAt.tr(), winningAuction.formattedStartDate),

          // ── Action Layer (Only shown if payment is pending) ───────────────
          if (!winningAuction.sold) ...[
            const SizedBox(height: 24),
            _buildOrderButton(context),
            const SizedBox(height: 8),
            _buildViewPaymentsLink(context, theme),
          ],
        ],
      ),
    );
  }

  /// Internal: Builds a stylized choice chip or badge based on [winningAuction.sold].
  Widget _buildStatusBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: winningAuction.sold
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: winningAuction.sold
            ? Border.all(color: theme.colorScheme.secondary, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (winningAuction.sold)
            Icon(Icons.check_circle, size: 16, color: theme.colorScheme.secondary),
          if (winningAuction.sold) const SizedBox(width: 4),
          Text(
            winningAuction.sold ? AppStrings.alreadyPaid.tr() : AppStrings.waitingForPayment.tr(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: winningAuction.sold
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Internal: Builds the primary CTA for converting a win into a formal order.
  Widget _buildOrderButton(BuildContext context) {
    return PrimaryButton(
      onPressed: () async {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              order: OrderModel.fromWinningAuction(winningAuction),
            ),
          ),
        );
      },
      text: AppStrings.continueToOrder.tr(),
      isLoading: false,
    );
  }

  /// Internal: Builds the contextual shortcut to view general payments.
  Widget _buildViewPaymentsLink(BuildContext context, ThemeData theme) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MyPaymentsScreen()),
          );
        },
        icon: Icon(Icons.receipt_long, size: 18, color: theme.colorScheme.primary),
        label: Text(
          AppStrings.viewPayments.tr(),
          style: TextStyle(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  /// Internal: Layout helper for producing consistent 'Label : Value' rows.
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
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
          child: Text(value, style: valueStyle ?? theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

