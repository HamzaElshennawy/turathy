import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../data/cart_repository.dart';
import '../domain/cart_model.dart';
import '../../addresses/domain/user_address_model.dart';
import '../../addresses/presentation/address_selection_screen.dart';
import '../../orders/presentation/order_confirmation_screen.dart';
import '../../orders/domain/order_model.dart';
import '../../orders/domain/order_item_model.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final userId = CachedVariables.userId;
      if (userId != null) {
        final _ = await ref.refresh(cartProvider(userId).future);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = CachedVariables.userId;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final cartAsync = ref.watch(cartProvider(userId));

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
            return RefreshIndicator(
              onRefresh: () async {
                return await ref.refresh(cartProvider(userId).future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
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
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    return await ref.refresh(cartProvider(userId).future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildCartItem(cartItems[index]);
                    },
                  ),
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
                Row(
                  children: [
                    Text(
                      '${product.price?.toStringAsFixed(0) ?? '0'} ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/RSA.svg',
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1B5E20),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
                gapH4,
                Row(
                  children: [
                    Text(
                      '${AppStrings.quantity.tr()}:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    gapW8,
                    InkWell(
                      onTap: () => _updateQuantity(item, item.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: () => _updateQuantity(item, item.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total.toStringAsFixed(0)} ',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SvgPicture.asset('assets/icons/RSA.svg', height: 18),
                  ],
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

  Future<void> _updateQuantity(CartItemModel item, int newQuantity) async {
    if (newQuantity < 1) return;
    final userId = CachedVariables.userId;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(cartRepositoryProvider)
          .updateQuantity(userId, item.productId, newQuantity);
      ref.invalidate(cartProvider(userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkout() async {
    setState(() => _isLoading = true);

    if (mounted) {
      double total = 0;
      final cartItems =
          ref.read(cartProvider(CachedVariables.userId!)).value ?? [];
      total = cartItems.fold<double>(0, (sum, item) {
        return sum + (item.product?.price ?? 0) * item.quantity;
      });

      // Step 1: Pick an address
      final selectedAddress = await Navigator.push<UserAddressModel>(
        context,
        MaterialPageRoute(builder: (context) => const AddressSelectionScreen()),
      );

      if (selectedAddress == null || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Navigate to OrderConfirmationScreen with selected address
      final tempOrder = OrderModel(
        id: 0,
        userId: CachedVariables.userId!,
        auctionId: 0,
        items: cartItems
            .map(
              (item) => OrderItemModel(
                id: 0,
                orderId: 0,
                productId: item.productId,
                quantity: item.quantity,
                price: item.product?.price ?? 0.0,
                product: item.product?.toJson(),
              ),
            )
            .toList(),
        total: total,
        date: DateTime.now(),
        addressId: selectedAddress.id,
        pCs: cartItems.length,
        codAmt: '0',
        weight: '1',
        itemDesc: cartItems.map((e) => e.product?.title ?? '').join(', '),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            order: tempOrder,
            preselectedAddress: selectedAddress,
          ),
        ),
      );

      setState(() => _isLoading = false);
    }
  }
}
