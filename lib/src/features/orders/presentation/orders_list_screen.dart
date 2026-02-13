import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/async_value_widget.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import 'package:turathy/src/features/orders/presentation/widgets/order_card.dart';
import 'package:turathy/src/features/orders/presentation/order_confirmation_screen.dart';
import '../../cart/presentation/cart_screen.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  int _selectedTab = 0; // 0: Store Orders, 1: Auctions

  @override
  Widget build(BuildContext context) {
    if (CachedVariables.userId == null) {
      return Center(child: Text(AppStrings.signInRequired.tr()));
    }

    final ordersValue = ref.watch(
      getUserOrdersProvider(CachedVariables.userId!),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppStrings.myOrders.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 45,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildTabItem(0, AppStrings.store.tr()),
                  _buildTabItem(1, AppStrings.auctions.tr()),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: AsyncValueWidget(
              value: ordersValue,
              data: (orders) {
                final filteredOrders = _filterOrders(orders);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found', // Should be localized, using hardcoded for now or AppStrings if available
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return OrderCard(
                      title: _getOrderTitle(order),
                      price: '${order.total} ${AppStrings.currency.tr()}',
                      status: order.orderStatus ?? order.paymentStatus,
                      imageUrl: _getOrderImage(order),
                      //imageUrl: _getOrderImage(order),
                      onTap: () {
                        // Navigate to details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderConfirmationScreen(order: order),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String text) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : Colors.transparent, // Primary Green
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    if (_selectedTab == 0) {
      // Store Orders: Have product_id or product data (and NO auction_id usually, or auction_id is null/0)
      // Based on schema, store orders have product_id. Auction orders have auction_id.
      // OrderModel has methods to check? No.
      // OrderModel fromJson assigns 0 to auctionId if null.
      // Let's check if there is a 'product' relation or 'auction' relation populated.
      // Or check IDs.
      return orders
          .where((order) => order.auctionId == 0 || order.auction == null)
          .toList();
    } else {
      // Auction Orders
      return orders
          .where((order) => order.auctionId != 0 || order.auction != null)
          .toList();
    }
  }

  String _getOrderTitle(OrderModel order) {
    if (order.product != null) {
      return order.product!['title'] ??
          order.product!['name'] ??
          order.itemDesc;
    } else if (order.auction != null) {
      return order.auction!['title'] ??
          order.auction!['name'] ??
          order.itemDesc;
    }
    return order.itemDesc;
  }

  String? _getOrderImage(OrderModel order) {
    String? url;
    if (order.product != null) {
      final product = order.product!;
      // Check for images list first
      if (product['images'] != null && (product['images'] as List).isNotEmpty) {
        url = (product['images'] as List).first.toString();
      } else {
        url = product['imageUrl']?.toString();
      }
    } else if (order.auction != null) {
      final auction = order.auction!;
      url =
          auction['image_url']?.toString() ?? auction['main_image']?.toString();
    }

    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${EndPoints.baseUrl}$url';
  }
}
