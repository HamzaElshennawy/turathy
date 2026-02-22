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
import 'package:turathy/src/features/orders/presentation/order_details_screen.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/winning_auction_model.dart';
import 'package:turathy/src/features/auctions/data/auction_payments_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_payment_model.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/my_payments_screen.dart';
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
    final winningsValue = ref.watch(userWinningAuctionsProvider);

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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(getUserOrdersProvider);
                ref.invalidate(userWinningAuctionsProvider);
                ref.invalidate(myPaymentsProvider);
                // Wait for the providers to refresh
                await Future.wait([
                  ref.read(
                    getUserOrdersProvider(CachedVariables.userId!).future,
                  ),
                  ref.read(userWinningAuctionsProvider.future),
                  ref.read(myPaymentsProvider.future),
                ]);
              },
              child: _buildList(ordersValue, winningsValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    AsyncValue<List<OrderModel>> ordersValue,
    AsyncValue<List<WinningAuctionModel>> winningsValue,
  ) {
    final paymentsValue = ref.watch(myPaymentsProvider);

    if (_selectedTab == 0) {
      return AsyncValueWidget(
        value: ordersValue,
        data: (orders) {
          final filtered = _filterOrders(orders);
          return _buildOrderListView(filtered, [], []);
        },
      );
    } else {
      // For Auctions, combine orders, winnings, and payments
      return ordersValue.when(
        data: (orders) {
          return winningsValue.when(
            data: (winnings) {
              return paymentsValue.when(
                data: (payments) {
                  final filteredOrders = _filterOrders(orders);
                  // Deduplicate: Don't show a 'Winning' if an 'Order' exists for the same auction
                  final dedupedWinnings = winnings.where((w) {
                    return !filteredOrders.any(
                      (o) => o.auctionId == w.auctionId,
                    );
                  }).toList();

                  return _buildOrderListView(
                    filteredOrders,
                    dedupedWinnings,
                    payments,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      );
    }
  }

  Widget _buildOrderListView(
    List<OrderModel> orders,
    List<WinningAuctionModel> winnings,
    List<AuctionPaymentModel> payments,
  ) {
    final combinedLength = orders.length + winnings.length;

    if (combinedLength == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
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
                    'No items found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: combinedLength,
      itemBuilder: (context, index) {
        if (index < winnings.length) {
          // Display Winning Auction (Dynamic Status)
          final winning = winnings[index];

          // Find payment for this winning
          final payment = payments.where((p) {
            if (winning.id != 0 && p.winningId == winning.id) return true;
            return p.productId == (winning.productId ?? 0);
          }).firstOrNull;

          Color statusColor = Colors.orange;
          String statusStr = AppStrings.waitingForPayment.tr();
          if (payment != null) {
            if (payment.isApproved) {
              statusStr = AppStrings.alreadyPaid.tr();
              statusColor = Colors.green;
            } else if (payment.isRejected) {
              statusStr = AppStrings.paymentRejected.tr();
              statusColor = Colors.red;
            } else {
              statusStr = AppStrings.paymentPending.tr();
              statusColor = Colors.orange;
            }
          }

          if (winning.sold) {
            statusStr = AppStrings.alreadyPaid.tr();
            statusColor = Colors.green;
          }

          return OrderCard(
            title: winning.auctionTitle,
            price: winning.formattedPrice,
            status: statusStr,
            statusColor: statusColor,
            imageUrl: _getWinningImage(winning),
            onTap: () {
              if (payment == null || payment.isRejected) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderConfirmationScreen(
                      order: OrderModel.fromWinningAuction(winning),
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyPaymentsScreen(),
                  ),
                );
              }
            },
          );
        } else {
          // Display finalized Order
          final order = orders[index - winnings.length];
          return OrderCard(
            title: _getOrderTitle(order),
            price: '${order.total} ${AppStrings.currency.tr()}',
            status: _getOrderStatusText(
              order.orderStatus ?? order.paymentStatus,
            ),
            statusColor: _getOrderStatusColor(
              order.orderStatus ?? order.paymentStatus,
            ),
            imageUrl: _getOrderImage(order),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(order: order),
                ),
              );
            },
          );
        }
      },
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
      // Store Orders: No auctionId AND no auction data
      return orders
          .where((order) => order.auctionId == 0 && order.auction == null)
          .toList();
    } else {
      // Auction Orders: Has auctionId OR auction data
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

  String? _getWinningImage(WinningAuctionModel winning) {
    String? url = winning.auctionImage;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${EndPoints.baseUrl}$url';
  }

  String _getOrderStatusText(String? status) {
    status = status?.toLowerCase() ?? 'pending';
    switch (status) {
      case 'confirmed':
        return AppStrings.completed.tr();
      case 'pending_approval':
        return AppStrings.waitingForApproval.tr();
      case 'shipped':
        return AppStrings.shipped.tr();
      case 'delivered':
        return AppStrings.delivered.tr();
      case 'cancelled':
      case 'rejected':
        return AppStrings.orderCanceled.tr();
      case 'initiated':
      case 'pending':
        return AppStrings.paymentPending.tr();
      case 'approved':
        return AppStrings.paymentApproved.tr();
      default:
        return AppStrings.pending.tr();
    }
  }

  Color _getOrderStatusColor(String? status) {
    status = status?.toLowerCase() ?? 'pending';
    switch (status) {
      case 'confirmed':
      case 'approved':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return const Color(0xFF2D4739);
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'pending_approval':
      case 'initiated':
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
