import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moyasar/moyasar.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'dart:io' show Platform;

import '../../../core/common_widgets/custom_card.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../data/order_repository.dart';
import '../domain/order_model.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  void _handlePaymentResult(
    dynamic result,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (result is PaymentResponse) {
      log(result.callbackUrl ?? 'No callback URL');
      switch (result.status) {
        case PaymentStatus.paid:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
          // TODO: Handle successful payment
          Navigator.popUntil(context, (route) => route.isFirst);
          ref.invalidate(userWinningAuctionsProvider);

          break;
        case PaymentStatus.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case PaymentStatus.initiated:
        case PaymentStatus.authorized:
        case PaymentStatus.captured:
          // These states are handled by the SDK
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderValue = ref.watch(createOrderProvider(order));
    final theme = Theme.of(context);

    final paymentConfig = PaymentConfig(
      // publishableApiKey: 'pk_test_i8K4Gsn8qhb3m5Q1MACMfgBWuAVb7Exr2D8djQfd',
      publishableApiKey: 'pk_live_oZiKtWnZr9yzgyoxhVKhKXtLG1Cbt3emJ3kRLGgW',
      amount: (order.total * 100)
          .round(), // Convert to smallest currency unit (halalas)
      description: 'Order #${order.id}',
      metadata: {'order_id': order.id, 'customer_name': order.cName},
      applePay: Platform.isIOS
          ? ApplePayConfig(
              merchantId:
                  'merchant.barakkh.sa', // Replace with your actual merchant ID
              label: 'Barakah',
              manual: false,
              saveCard: false,
            )
          : null,
    );
    log(
      'order is ${jsonEncode(order.toJson())}',
      time: DateTime.now(),
      level: 1,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.orderConfirmation.tr()),
        elevation: 0,
      ),
      body: orderValue.when(
        data: (data) {
          //PaymentConfig.callbackUrl =
          //'https://barakkh.sa/confirmOrder/${data.id}';
          PaymentConfig.callbackUrl =
              '${EndPoints.baseUrl}/confirmOrder/${data.id}';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSuccessIcon(theme),
                const SizedBox(height: 24),
                _buildOrderSummaryCard(context, data),
                const SizedBox(height: 16),
                _buildItemDetailsCard(context, data),
                const SizedBox(height: 16),
                _buildShippingDetailsCard(context, data),
                const SizedBox(height: 32),
                if (Platform.isIOS) ...[
                  ApplePay(
                    config: paymentConfig,
                    onPaymentResult: (result) =>
                        _handlePaymentResult(result, context, ref),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'or',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
                CreditCard(
                  config: paymentConfig,
                  onPaymentResult: (result) =>
                      _handlePaymentResult(result, context, ref),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            error.toString(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle,
        color: theme.colorScheme.primary,
        size: 64,
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.orderSummary.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(context, AppStrings.orderNumber.tr(), '#${order.id}'),
          const Divider(height: 24),
          _buildDetailRow(
            context,
            AppStrings.orderDate.tr(),
            DateFormat('dd/MM/yyyy').format(order.date),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            context,
            AppStrings.totalAmount.tr(),
            NumberFormat.currency(
              symbol: 'SAR ',
              decimalDigits: 2,
            ).format(order.total),
            valueStyle: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsCard(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.itemDetails.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            AppStrings.itemDescription.tr(),
            order.itemDesc,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            context,
            AppStrings.quantity.tr(),
            order.pCs.toString(),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            context,
            AppStrings.weight.tr(),
            '${order.weight} kg',
          ),
        ],
      ),
    );
  }

  Widget _buildShippingDetailsCard(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.shippingDetails.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(context, AppStrings.name.tr(), order.cName),
          const Divider(height: 24),
          _buildDetailRow(context, AppStrings.mobileNumber.tr(), order.cMobile),
          const Divider(height: 24),
          _buildDetailRow(context, AppStrings.address.tr(), order.cAddress),
          const Divider(height: 24),
          _buildDetailRow(context, AppStrings.city.tr(), order.cCity),
          const Divider(height: 24),
          _buildDetailRow(context, AppStrings.country.tr(), order.cCountry),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            style:
                valueStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
