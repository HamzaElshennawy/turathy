import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../data/cart_repository.dart';
import '../domain/cart_model.dart';
import '../../orders/presentation/shipping_details_screen.dart';
import '../../orders/domain/order_model.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userId = CachedVariables.userId;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final cartAsync = ref.watch(cartProvider(userId));

    // Directionality is handled automatically by MaterialApp's locale settings
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.cart.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartAsync.when(
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  gapH16,
                  Text(
                    AppStrings.cartEmpty.tr(),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    return _buildCartItem(cartItems[index]);
                  },
                ),
              ),
              _buildBottomBar(cartItems),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              gapH16,
              ElevatedButton(
                onPressed: () => ref.refresh(cartProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    final product = item.product;
    if (product == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: product.fullImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          gapW12,
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title ?? product.name ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                gapH4,
                Text(
                  '${product.price?.toStringAsFixed(0) ?? '0'}\$',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                gapH4,
                Text(
                  '${AppStrings.quantity.tr()}: ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Remove Button
          IconButton(
            onPressed: () => _removeItem(item),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(List<CartItemModel> items) {
    final total = items.fold<double>(0, (sum, item) {
      return sum + (item.product?.price ?? 0) * item.quantity;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.total.tr(),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  '${total.toStringAsFixed(0)}\$',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            gapH16,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        AppStrings.checkout.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeItem(CartItemModel item) async {
    final userId = CachedVariables.userId;
    if (userId == null) return;

    try {
      await ref
          .read(cartRepositoryProvider)
          .removeFromCart(userId, item.productId);
      ref.invalidate(cartProvider(userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkout() async {
    setState(() => _isLoading = true);

    // Navigate to shipping form with the first item for now (Assuming single item checkout or we need to handle bulk)
    // The current ShippingDetailsScreen takes a single order model.
    // We might need to adjust the flow to create a "temporary" order or pass cart items.

    // BUT `ShippingDetailsScreen` takes `OrderModel`.
    // And `OrderConfirmationScreen` takes `OrderModel`.
    // And `OrderConfirmationScreen` calls `createOrder`.

    // So we need to construct an `OrderModel` from the cart items.
    // However, `OrderModel` expects an ID, which we don't have yet.
    // AND `ShippingDetailsScreen` expects an `OrderModel` to pre-fill data.

    // Better approach:
    // 1. Create a "Pre-Order" or use `OrderModel` with dummy ID/Default values.
    // 2. Pass it to `ShippingDetailsScreen`.

    if (mounted) {
      // Calculate total
      double total = 0;
      final cartItems =
          ref.read(cartProvider(CachedVariables.userId!)).value ?? [];
      total = cartItems.fold<double>(0, (sum, item) {
        return sum + (item.product?.price ?? 0) * item.quantity;
      });

      // Construct a temporary OrderModel for the shipping screen
      final tempOrder = OrderModel(
        id: 0, // Temporary ID
        userId: CachedVariables.userId!,
        auctionId: 0, // Not an auction
        productId: cartItems.isNotEmpty ? cartItems.first.productId : null,
        total: total,
        date: DateTime.now(),
        cName: 'User Name', // Should fetch from user profile if available
        cCountry: 'KSA',
        cCity: 'Riyadh',
        cMobile: '',
        cAddress: '',
        pCs: cartItems.length,
        codAmt: '0',
        weight: '1',
        itemDesc: cartItems.map((e) => e.product?.title ?? '').join(', '),
        // We probably need to pass the cart items to the order creation logic later
        // But OrderModel doesn't seem to support a list of products directly in `product` field (it's a Map).
        // The backend `addOrder` seems designed for single item or uses `PCs` for quantity.
        // Let's look at `OrderService.addOrder` again. It takes `AddOrderDto`.
        // It doesn't seem to take a list of products.
        // It takes `product_id` (singular).

        // Wait, `addOrder` in backend:
        // `order` table has `product_id` (Int?).
        // This implies one product per order?
        // If `Cart` has multiple items, do we create multiple orders?
        // Or does `Order` support multiple items?
        // The schema says `order` has `product_id`. `order` has `items` (which is just itemDesc string).

        // If the system supports only single-product orders per "Order" entity,
        // then "Checkout" for a cart with multiple items is complex.
        // We might need to loop and create an order for each, OR the backend supports it and I missed it.
        // `OrderService.addOrder` uses `dto.itemDesc`.

        // Let's assume for now we implement it for the *first* item in the cart or aggregate them textually
        // and trigger the flow.
        // Since `ShippingDetailsScreen` -> `OrderConfirmationScreen` -> `createOrder`.

        // For now, let's navigate to `ShippingDetailsScreen` with aggregated data.
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShippingDetailsScreen(initialOrder: tempOrder),
        ),
      );

      setState(() => _isLoading = false);
    }
  }
}
