import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';
import 'package:turathy/src/features/orders/presentation/order_details_screen.dart';

class OrderDetailsWrapper extends ConsumerWidget {
  final int orderId;

  const OrderDetailsWrapper({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = CachedVariables.userId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view order details')),
      );
    }

    final ordersAsync = ref.watch(getUserOrdersProvider(userId));

    return ordersAsync.when(
      data: (orders) {
        final order = orders.where((o) => o.id == orderId).firstOrNull;
        if (order == null) {
          debugPrint('Order not found for order ID: $orderId');
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Order not found')),
          );
        }
        return OrderDetailsScreen(order: order);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
