import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppStrings.orderDetails.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(order),
            _buildOrderInfo(order, theme),
            _buildProductSection(order, theme),
            _buildShippingSection(order, theme),
            _buildTimelineSection(order, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(OrderModel order) {
    final status = order.orderStatus?.toLowerCase() ?? 'pending';
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'confirmed':
        color = Colors.green;
        icon = Icons.check_circle;
        text = AppStrings.completed.tr();
        break;
      case 'pending_approval':
        color = Colors.orange;
        icon = Icons.history;
        text = AppStrings.waitingForApproval.tr();
        break;
      case 'shipped':
        color = Colors.blue;
        icon = Icons.local_shipping;
        text = 'Shipped';
        break;
      case 'delivered':
        color = const Color(0xFF2D4739);
        icon = Icons.home;
        text = 'Delivered';
        break;
      default:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
        text = AppStrings.pending.tr();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (order.refNo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '#${order.refNo}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(OrderModel order, ThemeData theme) {
    return _buildCard(
      title: AppStrings.orderSummary.tr(),
      child: Column(
        children: [
          _buildInfoRow(
            AppStrings.orderDate.tr(),
            DateFormat('dd MMM yyyy').format(order.date),
          ),
          _buildInfoRow(
            AppStrings.totalAmount.tr(),
            '${order.total} ${AppStrings.currency.tr()}',
            isBold: true,
          ),
          if (order.paymentStatus != null)
            _buildInfoRow(AppStrings.status.tr(), order.paymentStatus!),
        ],
      ),
    );
  }

  Widget _buildProductSection(OrderModel order, ThemeData theme) {
    String? imageUrl;
    if (order.product != null) {
      final product = order.product!;
      if (product['images'] != null && (product['images'] as List).isNotEmpty) {
        imageUrl = (product['images'] as List).first.toString();
      } else {
        imageUrl = product['imageUrl']?.toString();
      }
    } else if (order.auction != null) {
      imageUrl =
          order.auction!['image_url']?.toString() ??
          order.auction!['main_image']?.toString();
    }

    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = '${EndPoints.baseUrl}$imageUrl';
    }

    return _buildCard(
      title: AppStrings.auctionProducts.tr(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.itemDesc,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '1 ${AppStrings.items.tr()}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSection(OrderModel order, ThemeData theme) {
    return _buildCard(
      title: AppStrings.shippingDetails.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(AppStrings.name.tr(), order.cName),
          _buildInfoRow(AppStrings.mobileNumber.tr(), order.cMobile),
          _buildInfoRow(AppStrings.country.tr(), order.cCountry),
          _buildInfoRow(AppStrings.city.tr(), order.cCity),
          const SizedBox(height: 8),
          Text(
            AppStrings.address.tr(),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(order.cAddress, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(OrderModel order, ThemeData theme) {
    final status = order.orderStatus?.toLowerCase() ?? 'pending';

    return _buildCard(
      title: 'Order Status Timeline',
      child: Column(
        children: [
          _buildTimelineItem(
            'Pending',
            'Order created and waiting for payment',
            isFirst: true,
            isDone: true,
          ),
          _buildTimelineItem(
            AppStrings.waitingForApproval.tr(),
            'Receipt uploaded and waiting for admin review',
            isDone: [
              'pending_approval',
              'confirmed',
              'shipped',
              'delivered',
            ].contains(status),
            isActive: status == 'pending_approval',
          ),
          _buildTimelineItem(
            'Confirmed',
            'Payment verified and order confirmed',
            isDone: ['confirmed', 'shipped', 'delivered'].contains(status),
            isActive: status == 'confirmed',
          ),
          _buildTimelineItem(
            'Shipped',
            'Item is on its way to you',
            isDone: ['shipped', 'delivered'].contains(status),
            isActive: status == 'shipped',
          ),
          _buildTimelineItem(
            'Delivered',
            'Item has been delivered successfully',
            isLast: true,
            isDone: status == 'delivered',
            isActive: status == 'delivered',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle, {
    bool isFirst = false,
    bool isLast = false,
    bool isDone = false,
    bool isActive = false,
  }) {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: isFirst
                    ? Colors.transparent
                    : (isDone ? const Color(0xFF2D4739) : Colors.grey[300]),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF2D4739)
                      : (isActive ? Colors.orange : Colors.white),
                  border: Border.all(
                    color: isDone ? const Color(0xFF2D4739) : Colors.grey[300]!,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast
                      ? Colors.transparent
                      : (isDone ? const Color(0xFF2D4739) : Colors.grey[300]),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: fontWeightBold,
                    color: isDone
                        ? Colors.black
                        : (isActive ? Colors.orange : Colors.grey[600]),
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  static const FontWeight fontWeightBold = FontWeight.bold;
}
